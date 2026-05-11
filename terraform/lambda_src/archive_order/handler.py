import os
import json
import boto3
import logging

s3 = boto3.client("s3")

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
    bucket = os.environ["ARCHIVE_BUCKET"]

    log("Order archival started", orderId=order_id)
    
    s3.put_object(
        Bucket=bucket,
        Key=f"{order_id}.json",
        Body=json.dumps(event)
    )

    log("Order archived", orderId=order_id)

    return {
        "message": "Order archived",
        "orderId": order_id
    }