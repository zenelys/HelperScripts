# Intro

This function aims to easy login to AWS ECR without typing long login command.

## Usage

`docker_login_aws [REGION_NAME]`. Default region is `us-east-1`.

## Requirements

- [aws cli](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- [jq](https://stedolan.github.io/jq/)

## Bash

Put following in `~/.bashrc`

```bash
docker_login_aws() {
  local region
  region='us-east-1'
  if [ $1 ]
  then
    region="$1"
  fi
  local account_id
  account_id="$(aws sts get-caller-identity | jq -r .Account)"
  echo -e "\n$(tput setaf 2)Logging in to $(tput setaf 4)${account_id}.dkr.ecr.${region}.amazonaws.com \n $(tput init)"
  aws ecr get-login-password | docker login --username AWS --password-stdin "${account_id}.dkr.ecr.${region}.amazonaws.com"
}
```

## Zsh

Put following in `~/.zshrc`

```bash
docker_login_aws() {
  local region
  region='us-east-1'
  if [ $1 ]
  then
    region="$1"
  fi
  local account_id
  account_id="$(aws sts get-caller-identity | jq -r .Account)"
  echo -e "\n$fg[green]Logging in to $fg[blue]${account_id}.dkr.ecr.${region}.amazonaws.com \n $reset_color"
  aws ecr get-login-password | docker login --username AWS --password-stdin "${account_id}.dkr.ecr.${region}.amazonaws.com"
}
```
