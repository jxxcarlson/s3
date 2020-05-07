#!/usr/bin/env python

"""
SOURCE: https://gist.github.com/bradmontgomery/2219997

Very simple HTTP server in python (Updated for Python 3.7)
Usage:
    ./dummy-web-server.py -h
    ./dummy-web-server.py -l localhost -p 8000
Send a GET request:
    curl http://localhost:8000
Send a HEAD request:
    curl -I http://localhost:8000
Send a POST request:
    curl -d "foo=bar&bin=baz" http://localhost:8000
"""
import argparse
from http.server import HTTPServer, BaseHTTPRequestHandler
import logging
import boto3
from urllib.parse import urlparse
from datetime import datetime, date, time, timezone
import json

from botocore.exceptions import ClientError

#
# key3832528868: "development/6780a705-221d-470c-86a3-9a3ccbefb6a1/${filename}"
# policy3832528868: "eyJleHBpcmF0aW9uIjoiMjAyMC0wNS0wNlQyMDoyMzo0NFoiLCJjb25kaXRpb25zIjpbeyJidWNrZXQiOiJnZXRjb2xsZWN0aXZlLXB1YmxpYy1maWxlcyJ9LFsic3RhcnRzLXdpdGgiLCIka2V5IiwiZGV2ZWxvcG1lbnQvNjc4MGE3MDUtMjIxZC00NzBjLTg2YTMtOWEzY2NiZWZiNmExLyJdLHsic3VjY2Vzc19hY3Rpb25fc3RhdHVzIjoiMjAxIn0seyJ4LWFtei1jcmVkZW50aWFsIjoiQUtJQVVFTElDMkZGTDdIUTNWWkovMjAyMDA1MDYvZXUtd2VzdC0zL3MzL2F3czRfcmVxdWVzdCJ9LHsieC1hbXotYWxnb3JpdGhtIjoiQVdTNC1ITUFDLVNIQTI1NiJ9LHsieC1hbXotZGF0ZSI6IjIwMjAwNTA2VDIwMDg0NFoifV19"
# success_action_status3832528868: "201"
# x_amz_algorithm3832528868: "AWS4-HMAC-SHA256"
# x_amz_credential3832528868: "AKIAUELIC2FFL7HQ3VZJ/20200506/eu-west-3/s3/aws4_request"
# x_amz_date3832528868: "20200506T200844Z"
# x_amz_signature3832528868: "43442ea5adcffbd4bead6364fc5fc35c6a482a19db831de9f2953e769f85664b"
# url3832528868: "https://getcollective-public-files.s3.eu-west-3.amazonaws.com/"

def create_presigned_post(bucket_name, object_name,
                          fields=None, conditions=None, expiration=3600):
    """Generate a presigned URL S3 POST request to upload a file

    :param bucket_name: string
    :param object_name: string
    :param fields: Dictionary of prefilled form fields
    :param conditions: List of conditions to include in the policy
    :param expiration: Time in seconds for the presigned URL to remain valid
    :return: Dictionary with the following keys:
        url: URL to post to
        fields: Dictionary of form fields and values to submit with the POST
    :return: None if error.
    """

    # Generate a presigned S3 POST URL
    s3_client = boto3.client('s3')
    try:
        response = s3_client.generate_presigned_post(bucket_name,
                                                     object_name,
                                                     Fields=fields,
                                                     Conditions=conditions,
                                                     ExpiresIn=expiration)
    except ClientError as e:
        logging.error(e)
        return None

    # The response contains the presigned URL and required fields
    return response

def create_presigned_url(bucket_name, object_name, expiration=3600):
    """Generate a presigned URL to share an S3 object

    :param bucket_name: string
    :param object_name: string
    :param expiration: Time in seconds for the presigned URL to remain valid
    :return: Presigned URL as string. If error, returns None.
    """

    # Generate a presigned URL for the S3 object
    s3_client = boto3.client('s3')
    try:
        response = s3_client.generate_presigned_url('get_object',
                                                    Params={'Bucket': bucket_name,
                                                            'Key': object_name},
                                                    ExpiresIn=expiration)
    except ClientError as e:
        logging.error(e)
        return None

    # The response contains the presigned URL
    return response

# The request
#
#     http://localhost:8000/?passwd=jollygreengiant!&bucket=noteimages&region=us-east&file=foo.jpg
#
# produces the response
#
#     {'url': 'https://noteimages.s3.amazonaws.com/',
#        'fields': {
#            'success_action_status': '201'
#          , 'x_amz_algorithm': 'AWS4-HMAC-SHA256'
#          , 'x_amz_date': '20200507T08051588833977Z'
#          , 'key': 'foo.jpg'
#          , 'AWSAccessKeyId': 'AKIAJQYJYCIAWH6DGHIQ'
#          , 'policy': 'eyJleHBpcmF0aW9uIjogIjIwMjAtMDUtMDdUMDk6NDY6MTdaIiwgImNvbmRpdGlvbnMiOiBbeyJidWNrZXQiOiAibm90ZWltYWdlcyJ9LCB7ImtleSI6ICJmb28uanBnIn1dfQ=='
#          , 'signature': 'O+9BPaXOfgE1Iv8Nq2U11C5GG34='
#          }
#       }
#
#     7 fields above, more in the return from the Ruby server
#     Among the missing:
#
#     (1) x_amz_credential3832528868: "AKIAUELIC2FFL7HQ3VZJ/20200506/eu-west-3/s3/aws4_request"
#     (2) url3832528868: "https://getcollective-public-files.s3.eu-west-3.amazonaws.com/"
#
#     I can create (1) by running create_presigned_url, turning its retuern
#     value into a json object, extracting the AWSAccessKeyId, then appending
#     data to it.  But this is surely not the right way to do it. Ugh!
#
#      Also, what about the 3832528868???
#

def presigned_url_data(bucket_name, object_name, region):

    # x_amz_credential3832528868: "AKIAUELIC2FFL7HQ3VZJ/20200506/eu-west-3/s3/aws4_request"
    fields = {
      'success_action_status' : "201",
      'x_amz_algorithm' : "AWS4-HMAC-SHA256",
      'x_amz_date' : datetime.now(timezone.utc).strftime("20%y%m%dT%H%m%sZ")
      }
    # x_amz_credential = j1.fields.AWSAccessKeyId + "/" + d.strftime("20%y%m%dT%H%m%sZ")+ "/" + region + "/s3/aws4_request"

    return create_presigned_post(bucket_name, object_name,
                                     fields, conditions=None, expiration=3600)

def respond_to(path):
    o = urlparse(path)
    parts = o.query.split("&")
    passwd = parts[0].split("=")[1]
    bucket_name = parts[1].split("=")[1]
    region = parts[2].split("=")[1]
    object_name = parts[3].split("=")[1]

    if passwd == "jollygreengiant!":
        return presigned_url_data(bucket_name, object_name, region)
        # return create_presigned_url(bucket_name, object_name)
    else:
        return "error"



class S(BaseHTTPRequestHandler):
    def _set_headers(self):
        self.send_response(200)
        self.send_header("Content-type", "text/html")
        self.end_headers()

    def _html(self, message):
        """This just generates an HTML document that includes `message`
        in the body. Override, or re-write this do do more interesting stuff.
        """
        content = f"<html><body><h1>{message}</h1></body></html>"
        return content.encode("utf8")  # NOTE: must return a bytes object!

    def do_GET(self):
        self._set_headers()
        print(self.path)
        self.wfile.write(self._html(respond_to(self.path)))

    def do_HEAD(self):
        self._set_headers()

    def do_POST(self):
        # Doesn't do anything with posted data
        self._set_headers()
        self.wfile.write(self._html("POST!"))


def run(server_class=HTTPServer, handler_class=S, addr="localhost", port=8000):
    server_address = (addr, port)
    httpd = server_class(server_address, handler_class)

    print(f"Starting httpd server on {addr}:{port}")
    httpd.serve_forever()


if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="Run a simple HTTP server")
    parser.add_argument(
        "-l",
        "--listen",
        default="localhost",
        help="Specify the IP address on which the server listens",
    )
    parser.add_argument(
        "-p",
        "--port",
        type=int,
        default=8000,
        help="Specify the port on which the server listens",
    )
    args = parser.parse_args()
    run(addr=args.listen, port=args.port)
