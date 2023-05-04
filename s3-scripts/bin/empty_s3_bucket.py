#!/usr/bin/env python3

import sys
import argparse
import botocore
import boto3

def permanently_delete_object(
    bucket_name: str = None,
    region: str = None,
    prefix: str = None,
    endpoint_url: str = None,
):
    """
    Permanently deletes a versioned object by deleting all of its versions.

    :param bucket: The bucket that contains the object.
    :param region: AWS region where bucket is located
    :param prefix: The objects prefix to delete.
    :param endpoint_url: The endpoint url of the s3 bucket.
    """
    s3 = boto3.resource("s3", region_name=region, endpoint_url=endpoint_url)
    bucket = s3.Bucket(bucket_name)
    _message = (
        f"Permanetely deleting s3://{bucket_name}/{prefix} ..."
        if prefix
        else f"permanently deleting all object versions in the s3://{bucket_name} ..."
    )
    print(_message, flush=True)
    try:
        if prefix != "all":
            bucket.object_versions.filter(Prefix=prefix).delete()
            print(
                f"Permanently deleted {prefix}/ in the s3://{bucket_name}.",
            )
        else:
            bucket.object_versions.delete()
            print(
                f"Permanently deleted all versions of all objects in the s3://{bucket_name}."
            )
    except botocore.exceptions.ClientError as ex:
        print(f"Couldn't delete all versions of {prefix} in {bucket_name}.\nError: {str(ex)}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--bucket", "-b", type=str, required=True, help="s3 bucket name"
    )
    parser.add_argument(
        "--prefix",
        "-p",
        type=str,
        required=True,
        help='s3 bucket prefix to delete, set "all" to empty entire bucket',
    )
    parser.add_argument(
        "--region",
        "-r",
        type=str,
        default="us-east-1",
        required=False,
        help="aws region of the s3 bucket",
    )
    parser.add_argument(
        "--endpoint",
        "-e",
        type=str,
        default=None,
        required=False,
        help="Enpoint url of the s3 bucket",
    )
    args = parser.parse_args()

    if args.prefix == 'all':
        prefix = None
    permanently_delete_object(
        bucket_name=args.bucket,
        region=args.region,
        prefix=prefix,
        endpoint_url=args.endpoint,
    )
