To use Boto3, you need to configure these files:

```
$ cat ~/.aws/config
[default]
region=us-east-1

$ cat ~/.aws/credentials
[default]
aws_access_key_id = ACCESS_KEY_ID
aws_secret_access_key = AWS_SECRET_ACCESS_KEY
```

You also have to install Boto3:


For Python2.7.. :


```
$ pip install boto3  
```

For Python3:

```
$ pip3 install boto3  
```

[Reference for Boto](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/quickstart.html)

[Boto: presigned urls](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/s3-presigned-urls.html)
