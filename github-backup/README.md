# GitHub Backup Script

## Overview

This Bash script facilitates the backup of GitHub repositories by cloning them, compressing the cloned data, and uploading it to an Cloud blob storage.
Upload file in the bucket will be `BUCKET_NAME/github-backups/CREATED_BACKUP_ZIP_NAME`.
Cloning can be done with 2 methods in following order:

1. `https` if `GH_BOT_USERNAME` and `GH_BOT_PAT` is provided
2. `ssh` if `GIT_SSH_COMMAND` env is provided

## Configuration

Configuration is done via env variables:

Name            | Description
--------------- | -------------------------------------------------------------------------------------------------------------------------------------
REPOSITORIES    | comma separate list of repository names, note: include `,` at the end
GH_BOT_USERNAME | GitHub username to use in https scheme
GH_BOT_PAT      | GitHub personal access token to use in https scheme
GIT_SSH_COMMAND | Git native env variable to use for pulling with ssh, refer [here](https://git-scm.com/book/en/v2/Git-Internals-Environment-Variables)
BACKUP_BUCKET   | AWS S3 or GCP GS bucket name to upload, `s3://...` and `gs:/...` accordingly
SLACK_CHANNEL   | slack channel id to report the status
SLACK_TOKEN     | slack token to use for authentication
