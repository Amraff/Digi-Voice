import boto3
import os
import uuid
import json

def lambda_handler(event, context):
    print("Received event:", event)

    # Accept both API Gateway (with "body") and direct invoke (no "body")
    if "body" in event:
        body = json.loads(event["body"])
    else:
        body = event

    recordId = str(uuid.uuid4())
    voice = body["voice"]
    text = body["text"]

    print(f'Generating new DynamoDB record with ID: {recordId}')
    print(f'Input Text: {text}')
    print(f'Selected Voice: {voice}')

    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(os.environ["DB_TABLE_NAME"])
    table.put_item(
        Item={
            "id": recordId,
            "text": text,
            "voice": voice,
            "status": "PROCESSING",
        }
    )

    client = boto3.client("sns")
    client.publish(
        TopicArn=os.environ["SNS_TOPIC"],
        Message=recordId
    )

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
        },
        "body": json.dumps(recordId),
    }
