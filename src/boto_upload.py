import boto3

s3 = boto3.resource('s3')

# Upload a new file
data = open('language-5.png', 'rb')
s3.Bucket('noteimages').put_object(Key='language-5.png', Body=data)
