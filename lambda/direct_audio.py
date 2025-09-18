import json
import boto3
import uuid
from botocore.exceptions import ClientError

def lambda_handler(event, context):
    try:
        # Parse request
        if event.get('body'):
            body = json.loads(event['body'])
        else:
            body = event
            
        text = body.get('text', 'Hello world')
        voice = body.get('voice', 'Matthew')
        
        # Initialize clients
        polly = boto3.client('polly')
        s3 = boto3.client('s3')
        
        # Generate unique filename
        audio_id = str(uuid.uuid4())
        s3_key = f"audio/{audio_id}.mp3"
        bucket_name = "polly-app-static-website-20251809"
        
        # Generate speech directly
        response = polly.synthesize_speech(
            Text=text,
            OutputFormat='mp3',
            VoiceId=voice
        )
        
        # Upload to S3
        s3.put_object(
            Bucket=bucket_name,
            Key=s3_key,
            Body=response['AudioStream'].read(),
            ContentType='audio/mpeg',
            ACL='public-read'
        )
        
        # Generate public URL
        audio_url = f"https://{bucket_name}.s3.amazonaws.com/{s3_key}"
        
        return {
            'statusCode': 200,
            'headers': {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Headers': 'Content-Type',
                'Access-Control-Allow-Methods': 'POST, OPTIONS'
            },
            'body': json.dumps({
                'id': audio_id,
                'url': audio_url,
                'status': 'COMPLETED'
            })
        }
        
    except Exception as e:
        return {
            'statusCode': 500,
            'headers': {
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({'error': str(e)})
        }