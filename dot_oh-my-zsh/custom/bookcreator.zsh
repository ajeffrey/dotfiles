# The next line updates PATH for the Google Cloud SDK.
#
if [ -f '$HOME/google-cloud-sdk/path.zsh.inc' ]; then . '$HOME/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '$HOME/google-cloud-sdk/completion.zsh.inc' ]; then . '$HOME/google-cloud-sdk/completion.zsh.inc'; fi
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
export PATH="/opt/homebrew/opt/python@3.9/libexec/bin:$PATH"
export PATH="/opt/homebrew/opt/openssl@3/bin:$PATH"
export PATH="$HOME/.config/yarn/global/node_modules/.bin:$PATH"

source "$HOME/google-cloud-sdk/completion.zsh.inc"
source "$HOME/google-cloud-sdk/path.zsh.inc"

# export GCLOUD_PROJECT=bookcreator-dev

export GOOGLE_APPLICATION_CREDENTIALS="$(readlink -f ~/creds/organisations-dev.json)"

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

valid_envs="local:dev:test:live"
envmode=dev
creds=""

updateenv() {
  case "$envmode" in
    local)
      unset GCLOUD_PROJECT
      unset GCLOUD_REGION
      ;;
    dev)
      export GCLOUD_PROJECT=bookcreator-dev
      export GCLOUD_REGION=europe-west2
      ;;
    test)
      export GCLOUD_PROJECT=bookcreator-test
      export GCLOUD_REGION=europe-west2
      ;;
    live)
      export GCLOUD_PROJECT=book-creator
      export GCLOUD_REGION=us-central1
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

updateenv

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

PROMPT="%B%(?:%F{green}➜ :%F{red}➜ )%b"
PROMPT+='$(env_prompt_info) %B%F{cyan}%c%f%b $(git_prompt_info)%b'

orgsdb() {
  if [ "$envmode" = "dev" ] || [ "$envmode" = "test" ]; then
    local orgip=$(lpass show BookCreator/alloydb --notes|dasel -r toml ".$envmode.ip")
    gcloud compute ssh alloydb-forwarder --project="$GCLOUD_PROJECT"  -- -NL 5432:$orgip:5432
  fi
}

orgsinternal() {
  gcloud beta run services proxy organisations-internal --project=$GCLOUD_PROJECT --region=$GCLOUD_REGION
}

csp() {
  cloud_sql_proxy -instances="${GCLOUD_PROJECT}:us-central1:analytics"
}

# alias orgsinternal="echo $GCLOUD_PROJECT/$GCLOUD_REGION && gcloud beta run services proxy organisations-internal --project=$GCLOUD_PROJECT --region=$GCLOUD_REGION"

