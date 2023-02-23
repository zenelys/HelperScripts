# Intro

Sometimes we have too many AWS Profiles, following shell functions makes it easy to switch profiles and set credentials.

## Functions

- `set_profile_aws PROFILE_NAME`: Equivalent of `export AWS_PROFILE=PROFILE_NAME`, but with autocompletion
- `set_creds_aws A_KEY S_KEY TOKEN`: Equivalent of `export AWS_ACCESS_KEY=A_KEY AWS_SECRET_ACCESS_KEY=S_KEY [AWS_SESSION_TOKEN=TOKEN]`, but shorter.

## Bash

Put following in `~/.bashrc`

```bash
_complete_set_profile_aws() {
  if [ "${#COMP_WORDS[@]}" != "2" ]; then
    return
  fi
  local profile_names
  readarray -t profile_names <<< $(grep -E '\[profile' ~/.aws/config | grep -o -E '[[:space:]][[:alnum:]].+[[:alnum:]]')
  if ( grep default ~/.aws/config &>/dev/null )
  then
    profile_names+=( 'default' )
  fi
  COMPREPLY=($(compgen -W "${profile_names[*]}" -- "${COMP_WORDS[1]}"))
}

set_profile_aws() {
  unset AWS_ACCESS_KEY_ID 
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
  if [ "$#" -eq 0 ] 
  then 
    unset AWS_PROFILE
  else
    export AWS_PROFILE="$1"
  fi
  if [ $AWS_PROFILE ]
  then
    echo -e "\n$(tput setaf 2)AWS profile is set to $(tput setaf 1)${AWS_PROFILE}\n $(tput init)"
  else
    echo -e "\n$(tput setaf 4) AWS Profile is unset\n$(tput init)"
  fi
}

complete -F _complete_set_profile_aws set_profile_aws 

set_creds_aws() {
  if ! [ "$1" ]
  then
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    echo -e "\n$(BLUE) AWS credentials are unset\n$(RESET)"
    return
  fi
  unset  AWS_PROFILE AWS_SESSION_TOKEN
  export AWS_ACCESS_KEY_ID="$1"
  export AWS_SECRET_ACCESS_KEY="$2"
  [ -n "$3" ] && export AWS_SESSION_TOKEN="$3"
}
```

## Zsh

Put following in `~/.zshrc`

If the following already exists, avoid it.

```bash
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit
```

```bash
_complete_set_profile_aws() {
  if [ "${#COMP_WORDS[@]}" != "2" ]; then
    return
  fi
  local profile_names
  profile_names="$(grep -E '\[profile' ~/.aws/config | grep -o -E '[[:space:]][[:alnum:]].+[[:alnum:]]')"
  if ( grep default ~/.aws/config &>/dev/null )
  then
    profile_names+=( 'default' )
  fi
  COMPREPLY=($(compgen -W "${profile_names[*]}" -- "${COMP_WORDS[1]}"))
}

set_profile_aws() {
  unset AWS_ACCESS_KEY_ID
  unset AWS_SECRET_ACCESS_KEY
  unset AWS_SESSION_TOKEN
  if [ "$#" -eq 0 ]
  then
    unset AWS_PROFILE
  else
    export AWS_PROFILE="$1"
  fi
  if [ $AWS_PROFILE ]
  then
    echo -e "\n$(tput setaf 2)AWS profile is set to $(tput setaf 1)${AWS_PROFILE}\n $(tput init)"
  else
    echo -e "\n$(tput setaf 4) AWS Profile is unset\n$(tput init)"
  fi
}

complete -F _complete_set_profile_aws set_profile_aws

set_creds_aws() {
  if ! [ "$1" ]
  then
    unset AWS_ACCESS_KEY_ID
    unset AWS_SECRET_ACCESS_KEY
    unset AWS_SESSION_TOKEN
    echo -e "AWS credentials are unset"
    return
  fi
  unset  AWS_PROFILE AWS_SESSION_TOKEN
  export AWS_ACCESS_KEY_ID="$1"
  export AWS_SECRET_ACCESS_KEY="$2"
  [ -n "$3" ] && export AWS_SESSION_TOKEN="$3"
}
```
