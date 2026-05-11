import os
import json
import boto3
import logging
from decimal import Decimal
from botocore.exceptions import ClientError

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table(os.environ["ORDERS_TABLE"])

logger = logging.getLogger()
logger.setLevel(logging.INFO)

SERVICE_NAME = os.environ.get("SERVICE_NAME", "order-service")
ENVIRONMENT = os.environ.get("ENVIRONMENT", "dev")


def log(message, level="INFO", **kwargs):
    log_entry = {
        "service": SERVICE_NAME,
        "environment": ENVIRONMENT,
        "message": message,
        **kwargs
    }

    if level == "ERROR":
        logger.error(json.dumps(log_entry))
    elif level == "WARNING":
        logger.warning(json.dumps(log_entry))
    else:
        logger.info(json.dumps(log_entry))


def lambda_handler(event, context):
    order_id = event["orderId"]
    amount = Decimal(str(event["totalAmount"]))
    log("ProcessPayment started", orderId=order_id)
    # 🔴 Simulate failure
    if event.get("simulatePaymentFailure") == True:
        log("Simulated payment failure",
            level="ERROR",
            orderId=order_id)
        raise Exception("Simulated payment gateway failure")

    try:
        # Idempotent write
        table.put_item(
            Item={
                "orderId": order_id,
                "recordType": "PAYMENT",
                "status": "PAYMENT_COMPLETED",
                "amount": amount
            },
            ConditionExpression="attribute_not_exists(orderId)"
        )
    except ClientError as e:
        if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
            log("Payment already processed",
            level="ERROR",
            orderId=order_id)
            return {"message": "Payment already processed", "orderId": order_id}
        else:
            raise
    log("ProcessPayment successfull", orderId=order_id)
    return {
        "message": "Payment successful",
        "orderId": order_id
    }