#!/bin/bash

set -eE

REPOS_SUCCEEDED=()
REPOS_FAILED=()
REPO_NAME_TEMPLATE='{
    "type": "rich_text_section",
    "elements": []
}'
SLACK_TEMPLATE='{
    "icon_emoji": ":hammer_and_wrench:",
    "username": "github-backups",
    "blocks": [
        {
            "type": "rich_text",
            "elements": [
                {
                    "type": "rich_text_section",
                    "elements": [
                        {
                            "type": "text",
                            "text": "GitHub Repository Backup Report\n\n"
                        }
                    ]
                },
                {
                    "type": "rich_text_section",
                    "elements": [
                        {
                            "type": "text",
                            "text": "Backup Success:\n\n"
                        }
                    ]
                },
                {
                    "type": "rich_text_list",
                    "style": "bullet",
                    "indent": 0,
                    "border": 0,
                    "elements": []
                },
                {
                    "type": "rich_text_section",
                    "elements": [
                        {
                            "type": "text",
                            "text": "\nBackup Failed:\n\n"
                        }
                    ]
                },
                {
                    "type": "rich_text_list",
                    "style": "bullet",
                    "indent": 0,
                    "border": 0,
                    "elements": []
                },
                {
                    "type": "rich_text_section",
                    "elements": [
                        {
                            "type": "text",
                            "text": "\nBackup Location: "
                        },
                        {
                            "type": "text",
                            "text": ""
                        }
                    ]
                }
            ]
        }
    ]
}'

log() {
    echo "[${1^^}]: $2"
}

notify_slack() {
    local repos
    local body
    body="$SLACK_TEMPLATE"
    for i in "${REPOS_SUCCEEDED[@]}"; do
        repo_status="$(R="{\"type\": \"text\",\"text\": \"$i\"}" yq -oj ".elements += env(R)" <<< "$REPO_NAME_TEMPLATE")"
        body=$(RS="$repo_status" yq -oj '.blocks[0].elements[2].elements += env(RS)' <<< "$body")
    done
    for i in "${REPOS_FAILED[@]}"; do
        repo_status="$(R="{\"type\": \"text\",\"text\": \"$i\"}" yq -oj ".elements += env(R)" <<< "$REPO_NAME_TEMPLATE")"
        body=$(RS="$repo_status" yq -oj '.blocks[0].elements[4].elements += env(RS)' <<< "$body")
    done
    body="$(yq -oj '.channel = env(SLACK_CHANNEL)' <<< "$body")"
    body=$(RS="$repo_status" yq -oj '.blocks[0].elements[5].elements[1].text = env(BACKUP_LOCATION)' <<< "$body")
    resp="$(curl -s -X POST https://slack.com/api/chat.postMessage \
        -H 'Content-Type: application/json; charset=utf-8' \
        -H "Authorization: Bearer $SLACK_TOKEN" \
        -d "$body")"
    if [ "$(yq -p json .ok <<< "$resp")" != 'true' ]; then
        log error "failed to post status in slack: $resp"
    else
        log info "posted status in slack"
    fi
}

upload() {
    scheme="$(cut -d':' -f1 <<< "$BACKUP_BUCKET")"
    case $scheme in
        s3)
            if ! (upload_s3 "$1"); then
                REPOS_SUCCEEDED=()
                REPOS_FAILED=()
            fi
        ;;
        gs)
            if ! (upload_gs "$1"); then
                REPOS_SUCCEEDED=()
                REPOS_FAILED=()
            fi
        ;;
        azure)
            if ! (upload_azure "$1"); then
                REPOS_SUCCEEDED=()
                REPOS_FAILED=()
            fi
        ;;
        *)
            log error "upload storage not supported: $BACKUP_BUCKET"
            exit 1
        ;;
    esac
}

upload_s3() {
pip3 install -qqq boto3 --break-system-packages
if ! ( cat << EOF | python3
import os
import sys
import boto3
try:
    bucket_name = os.environ.get('BACKUP_BUCKET').rsplit('/', maxsplit=1)[-1]
    boto3.client('s3').uplod_file(Filename='$1', Bucket=bucket_name, Key='github-backups/$1')
except Exception as ex:
    print('[ERROR] ' + str(ex))
    sys.exit(1)

EOF
); then
    log error "failed to upload backup"
    exit 1
else
    log info "backup uploaded"
fi
}

upload_gs() {
pip install -qqq google-cloud-storage --break-system-packages
if ! ( cat << EOF | python3
import os
import sys
from google.cloud.storage import Client
try:
    bucket_name = os.environ.get('BACKUP_BUCKET').rsplit('/', maxsplit=1)[-1]
    client = Client()
    bucket = client.bucket(bucket_name=bucket_name)
    blob = bucket.blob('github-backups/$1')
    blob.upload_from_filename(filename='$1')
except Exception as ex:
    print('[ERROR] ' + str(ex))
    sys.exit(1)
EOF
); then
    log error "failed to upload backup"
    exit 1
else
    log info "backup uploaded"
fi
}

upload_azure() {
    log error "not implemented"
    exit 1
}

install_deps() {
    source /etc/os-release
    case $ID in
        debin | ubuntu)
            if [ "$EUID" != 0 ]; then
                sudo apt-get update -qq
                sudo apt-get -qq install -y git zip python3 python3-pip curl ssh
                if ! (hash yq); then
                    sudo curl -fsSLo "/usr/bin/yq" "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
                    chmod +x /usr/bin/yq
                fi
            else
                apt-get update -qq
                apt-get -qq install -y git zip python3 python3-pip curl ssh
                if ! (hash yq); then
                    curl -fsSLo "/usr/bin/yq" "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
                    chmod +x /usr/bin/yq
                fi
            fi
            ;;
        fedora |centos | redhat | alma)
            if [ "$EUID" != 0 ]; then
                sudo yum install -q -y git zip python3 python3-pip curl ssh
                if ! (hash yq); then
                    sudo curl -fsSLo "/usr/bin/yq" "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
                    chmod +x /usr/bin/yq
                fi
            else
                yum install -q -y git zip python3 python3-pip curl ssh
                if ! (hash yq); then
                    curl -fsSLo "/usr/bin/yq" "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
                    chmod +x /usr/bin/yq
                fi
            fi
            ;;
        alpine)
            if [ "$EUID" != 0 ]; then
                sudo apk add -qqq git zip python3 py3-pip curl openssh
                if ! (hash yq); then
                    sudo curl -fsSLo "/usr/bin/yq" "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
                    chmod +x /usr/bin/yq
                fi
            else
                apk add -qqq git zip python3 py3-pip curl openssh
                if ! (hash yq); then
                    curl -fsSLo "/usr/bin/yq" "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64"
                    chmod +x /usr/bin/yq
                fi
            fi
            ;;
        *)
            log error "os not supported: $ID"
            exit 1
        ;;
    esac
}

git_clone() {
    rm .error_log &>/dev/null || true
    if [ "$GH_BOT_USERNAME" ] && [ "$GH_BOT_PAT" ]; then
        git clone --mirror "https://$GH_BOT_USERNAME:$GH_BOT_PAT@github.com/$GH_ORG/$1" 2>.error_log
    else
        git clone --mirror "git@github.com/$GH_ORG/$1" 2>.error_log
    fi
    git clone "$1.git" "repos/$1" 2>>.error_log
    if [ -f .log ]; then
        log error "$(cat .log)"
    fi
}

install_deps
today=$(date +"%Y-%m-%d_%H-%M-%S")
rm -rf backups || true
IFS='' readarray -t -d ',' repos <<< "${REPOSITORIES}"
mkdir backups
cd backups
mkdir repos
repo_count="${#repos[@]}"
for ((i=0;i<repo_count-1;i++)); do
    r="${repos[$i]}"
    log info "downloding repo: $r"
    if ! (git_clone "$r"); then
       log error "failed to backup repository: $r"
       REPOS_FAILED+=( "$r" )
       continue
    fi
    REPOS_SUCCEEDED+=( "$r" )
done
log info "creating zip from repo directories"
zip -q -r "$today.zip"  "repos"
log info "uploading backup to $BACKUP_BUCKET"
upload "$today.zip"
export BACKUP_LOCATION="$BACKUP_BUCKET/github-backups/$today.zip"
notify_slack
