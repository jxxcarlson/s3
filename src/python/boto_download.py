import boto3
import botocore

Bucket = "noteimages"
Key = "robin2.jpg"
outPutName = "robin3.jpg"

s3 = boto3.resource('s3')
try:
    s3.Bucket(Bucket).download_file(Key, outPutName)
except botocore.exceptions.ClientError as e:
    if e.response['Error']['Code'] == "404":
        print("The object does not exist.")
    else:
        raise
