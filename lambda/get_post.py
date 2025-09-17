import boto3
import os
from boto3.dynamodb.conditions import Key, Attr
import json

def lambda_handler(event, context):
    postId = event.get("queryStringParameters", {}).get("postId", "")

    dynamodb = boto3.resource('dynamodb')
    table = dynamodb.Table(os.environ['DB_TABLE_NAME'])

    if not postId:
        return {
            "statusCode": 400,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"error": "Missing or empty postId"})
        }

    if postId == "*":
        items = table.scan()
    else:
        items = table.query(
            KeyConditionExpression=Key('id').eq(postId)
        )

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*"
        },
        "body": json.dumps(items["Items"])
    }
