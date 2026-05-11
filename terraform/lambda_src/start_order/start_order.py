import json
import boto3
import os

stepfunctions = boto3.client("stepfunctions")

STATE_MACHINE_ARN = os.environ["STATE_MACHINE_ARN"]


def lambda_handler(event, context):

    body = json.loads(event["body"])

    response = stepfunctions.start_execution(
        stateMachineArn=STATE_MACHINE_ARN,
        input=json.dumps(body)
    )

    return {
        "statusCode": 200,
        "body": json.dumps({
            "executionArn": response["executionArn"]
        })
    }