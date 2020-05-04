import boto3

s3 = boto3.client('s3')
url = s3.generate_presigned_url(
    'get_object',
     Params={
        'Bucket': 'noteimage',
        'Key': 'robin3.jpg',
    },
    HttpMethod="GET",
)
