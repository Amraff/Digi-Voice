import json
import boto3

def lambda_handler(event, context):
    polly = boto3.client("polly")
    voices = []

    # Use paginator to be safe if AWS returns multiple pages
    try:
        paginator = polly.get_paginator("describe_voices")
        for page in paginator.paginate():
            for v in page.get("Voices", []):
                voices.append({
                    "Name": v.get("Name"),
                    "Id": v.get("Id") or v.get("Name"),
                    "LanguageCode": v.get("LanguageCode"),
                    "LanguageName": v.get("LanguageName"),
                    "Gender": v.get("Gender"),
                    # you can include additional fields if you want
                })
    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
            "body": json.dumps({"error": str(e)})
        }

    return {
        "statusCode": 200,
        "headers": {"Content-Type": "application/json", "Access-Control-Allow-Origin": "*"},
        "body": json.dumps({"voices": voices})
    }