import json
import os
import boto3
import logging
from decimal import Decimal
from datetime import datetime
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

def handler(event, context):
    print(f"Received event: {json.dumps(event)}")
    log("Received event",level="INFO",input=json.dumps(event))
 
    order_id = event["orderId"]
    customer_id = event["customerId"]
    amount = Decimal(str(event["totalAmount"]))

    try:
        if event["totalAmount"] <= 0:
            log("Invalid order amount",
            level="ERROR",
            orderId=order_id)
            raise Exception("Invalid order amount")

        table.put_item(
            Item={
                "orderId": order_id,
                "recordType": "ORDER",
                "customerId": customer_id,
                "amount": amount,
                "status": "CREATED"
            },
            ConditionExpression="attribute_not_exists(orderId)"
        )

        event["validatedAt"] = datetime.utcnow().isoformat()
        log("Order created", orderId=order_id)
        return event
    except ClientError as e:

        if e.response["Error"]["Code"] == "ConditionalCheckFailedException":
            # Order already exists
            log("Duplicate order detected",
            level="WARNING",
            orderId=order_id)
            return {
                "orderId": order_id,
                "duplicate": True
            }
    else:
        raise