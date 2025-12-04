import json  
import hashlib  
import boto3  
import pymysql  
import os  

dynamodb = boto3.resource('dynamodb')  
table = dynamodb.Table('HelpRequests')  

def lambda_handler(event, context):  
    body = json.loads(event['body'])  
    request_data = body.get('request', {})  # Example: {'location': 'City', 'time': '2025-12-03', 'description': 'Flood help'}  

    # Create hash for deduplication (Task 1)  
    hash_obj = hashlib.sha256(json.dumps(request_data, sort_keys=True).encode())  
    request_id = hash_obj.hexdigest()  

    # Check if duplicate in DynamoDB  
    response = table.get_item(Key={'RequestID': request_id})  
    if 'Item' in response:  
        return {'statusCode': 200, 'body': json.dumps('Duplicate request')}  

    # Save to DynamoDB  
    table.put_item(Item={'RequestID': request_id, 'Data': request_data})  

    # Save to RDS (secure parameterized query, Task 2)  
    rds_host = os.environ['RDS_HOST']  # We'll set this env var  
    rds_user = os.environ['RDS_USER']  
    rds_pass = os.environ['RDS_PASS']  
    rds_db = os.environ['RDS_DB']  

    conn = pymysql.connect(host=rds_host, user=rds_user, password=rds_pass, db=rds_db)  
    with conn.cursor() as cur:  
        cur.execute(  
            "INSERT INTO requests (id, data) VALUES (%s, %s)",  
            (request_id, json.dumps(request_data))  
        )  
    conn.commit()  
    conn.close()  

    return {'statusCode': 200, 'body': json.dumps('Request saved')}  