
# Uploading files to S3

(Thibault, your text here)


## Setting up a Python server to provide presigned urls

### Installation

```
$ brew install Python3
$ brew install pip3
$ pip3 install boto3  
```

### Configuration

```
# File: ~/.aws/config
[default]
region=us-east-1

# File: ~/.aws/credentials
[default]
aws_access_key_id = ACCESS_KEY_ID
aws_secret_access_key = AWS_SECRET_ACCESS_KEY
```

### Operation

Start the server, assuming you are in `./src` using

```
$ python3 server.py
```

Then the (Http GET) request

```
http://localhost:8000/?passwd=jollygreengiant!&bucket=noteimages&file=foo.jpg
```

will return a presigned url for the bucket `noteimages` and the file `foo.jpg`.
You can change the password to anything you want, but be sure to change it in the
server as well.  **Note:** This is a low-tech, low-security measure to given
minimal protection to your server.  It is intended for testing purposes only,
not production, and it should only be run locally.

### References

[Reference for Boto](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/quickstart.html)

[Boto: presigned urls](https://boto3.amazonaws.com/v1/documentation/api/latest/guide/s3-presigned-urls.html)
