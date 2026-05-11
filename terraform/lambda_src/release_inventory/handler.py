import os
import boto3
import logging
import json

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
    log("Release inventory started", orderId=order_id)

    table.update_item(
        Key={"orderId": order_id,"recordType": "ORDER"},
        UpdateExpression="SET #s = :status",
        ExpressionAttributeNames={"#s": "status"},
        ExpressionAttributeValues={":status": "INVENTORY_RELEASED"}
    )
    log("Inventory release", orderId=order_id)
    return {
        "message": "Inventory released",
        "orderId": order_id
    }