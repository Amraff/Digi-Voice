import boto3
import os
import json
from botocore.exceptions import BotoCoreError, ClientError

def lambda_handler(event, context):
    print("Received event:", json.dumps(event))

    # SNS sends recordId as the message
    record_id = event["Records"][0]["Sns"]["Message"]
    print(f"Processing recordId: {record_id}")

    dynamodb = boto3.resource("dynamodb")
    table = dynamodb.Table(os.environ["DB_TABLE_NAME"])

    # Get the text + voice from DynamoDB
    try:
        response = table.get_item(Key={"id": record_id})
        item = response.get("Item")
        if not item:
            raise Exception("Record not found in DynamoDB")

        text = item["text"]
        voice = item["voice"]
        print(f"Retrieved from DB: text='{text}', voice='{voice}'")
    except Exception as e:
        print(f"Error fetching record from DynamoDB: {e}")
        raise

    polly = boto3.client("polly")
    s3 = boto3.client("s3")
    bucket = os.environ["BUCKET_NAME"]
    s3_key = f"audio/{record_id}.mp3"

    try:
        # Convert text to speech
        polly_response = polly.synthesize_speech(
            Text=text,
            OutputFormat="mp3",
            VoiceId=voice
        )

        if "AudioStream" not in polly_response:
            raise Exception("Polly did not return audio")

        # Upload to S3
        with polly_response["AudioStream"] as stream:
            s3.upload_fileobj(
                stream,
                bucket,
                s3_key,
                ExtraArgs={"ContentType": "audio/mpeg"}
            )

        # Public S3 URL
        file_url = f"https://{bucket}.s3.amazonaws.com/{s3_key}"
        print(f"Uploaded file to {file_url}")

        # Update DynamoDB with URL + status
        table.update_item(
            Key={"id": record_id},
            UpdateExpression="SET #s = :s, #u = :u",
            ExpressionAttributeNames={"#s": "status", "#u": "url"},
            ExpressionAttributeValues={":s": "COMPLETED", ":u": file_url}
        )
        print(f"Updated DynamoDB record {record_id} with COMPLETED + URL")

    except (BotoCoreError, ClientError) as e:
        print(f"Error during Polly/S3/DynamoDB processing: {e}")
        table.update_item(
            Key={"id": record_id},
            UpdateExpression="SET #s = :s",
            ExpressionAttributeNames={"#s": "status"},
            ExpressionAttributeValues={":s": "FAILED"}
        )
        raise

    return {"status": "ok", "id": record_id}
