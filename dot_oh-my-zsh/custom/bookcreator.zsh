# The next line updates PATH for the Google Cloud SDK.
if [ -f '$HOME/google-cloud-sdk/path.zsh.inc' ]; then . '$HOME/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '$HOME/google-cloud-sdk/completion.zsh.inc' ]; then . '$HOME/google-cloud-sdk/completion.zsh.inc'; fi
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
export PATH="/opt/homebrew/opt/python@3.9/libexec/bin:$PATH"
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
export PATH="$HOME/.config/yarn/global/node_modules/.bin:$PATH"

# export GCLOUD_PROJECT=bookcreator-dev

alias csp="cloud_sql_proxy -instances=bookcreator-dev:us-central1:analytics=tcp:3311,bookcreator-test:us-central1:analytics=tcp:3312,book-creator:us-central1:analytics=tcp:3313,book-creator:us-central1:analytics-replica=tcp:3314"
alias cspd="cloud_sql_proxy -instances=bookcreator-dev:us-central1:analytics=tcp:::1:3311"
alias devorgsdb="gcloud compute ssh alloydb-forwarder --project=bookcreator-dev  -- -NL 5432:10.127.32.32:5432"
alias testorgsdb="gcloud compute ssh alloydb-forwarder --project=bookcreator-test --zone europe-west2-a -- -NL 5432:10.45.1.2:5432"
alias devorgsinternal="gcloud beta run services proxy organisations-internal --project=bookcreator-dev --region=europe-west2"
alias testorgsinternal="gcloud beta run services proxy organisations-internal --project=bookcreator-test --region=europe-west2"
# export GOOGLE_APPLICATION_CREDENTIALS="$(readlink -f ~/creds/organisations-dev.json)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

valid_envs="dev:test:live"
envmode=dev
creds=""

#!/bin/bash

updateenv() {
  case "$envmode" in
    dev)
      export GCLOUD_PROJECT=bookcreator-dev
      ;;
    test)
      export GCLOUD_PROJECT=bookcreator-test
      ;;
    live)
      export GCLOUD_PROJECT=book-creator
      ;;
  esac

  if [ -n "$creds" ]; then
    filepath=$(readlink -f "$HOME/creds/$creds-$envmode.json")
    if [ -f "$filepath" ]; then
      export GOOGLE_APPLICATION_CREDENTIALS="$filepath"
    else
      unset GOOGLE_APPLICATION_CREDENTIALS
      echo "application credentials not found, unsetting"
    fi
  fi
}

setenv() {
  if [ -z "$1" ]; then
    echo "please provide an env name"
    return 255
  fi

  if [[ ":$valid_envs:" != *:$1:* ]]; then
    echo "please provide a valid env"
    return 255
  fi

  envmode="$1"
  updateenv
}

setcreds() {
  if [ -z "$1" ]; then
    echo "please provide a service account name"
    return 255
  fi
  creds="$1"
  updateenv
}

fgcol() {
  echo -n "%F{$1}$2%f"
}

bgcol() {
  echo -n "%K{$1}$2%k"
}

env_prompt_info() {
  prompt=""
  if [ -n "$creds" ]; then
    prompt+="$(fgcol "#3333e8" $creds)$(fgcol black @)"
  fi
  prompt+="$(fgcol "#000000" $envmode)"
  echo -n %B$(bgcol white " $prompt ")%b
}

go() {
  cd "$HOME/Projects/$1"
}

chpwd() {
  if [ -f "./.nvmrc" ]; then
    nvm use
  fi
}

PROMPT="%B%(?:%F{green}➜ :%F{red}➜ )%b"
PROMPT+='$(env_prompt_info) %B%F{cyan}%c%f%b $(git_prompt_info)%b'

