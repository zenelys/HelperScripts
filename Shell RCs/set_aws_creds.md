# Intro

Sometimes we have too many AWS Profiles, following shell functions makes it easy to switch profiles and set credentials.

## Functions

- `set_profile_aws PROFILE_NAME`: Equivalent of `export AWS_PROFILE=PROFILE_NAME`, but with autocompletion
- `set_creds_aws A_KEY S_KEY TOKEN`: Equivalent of `export AWS_ACCESS_KEY=A_KEY AWS_SECRET_ACCESS_KEY=S_KEY [AWS_SESSION_TOKEN=TOKEN]`, but shorter.


## Bash

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
```

## Zsh

```bash
_set_profile_aws() {
  if [[ ${words[2]} ]]
  then
    return
  fi
  compadd $(grep -E '\[profile' ~/.aws/config | grep -o -E '[[:space:]][[:alnum:]].+[[:alnum:]]')
  if ( grep default ~/.aws/config &>/dev/null )
  then
    compadd 'default'
  fi
}

compdef _set_profile_aws set_profile_aws

function set_profile_aws() {
  autoload colors; colors
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
    echo -e "\n$fg[green]AWS profile is set to $fg[red]${AWS_PROFILE}\n $reset_color"
  else
    echo -e "\n$fg[blue] AWS Profile is unset\n$reset_color"
  fi
}
```
