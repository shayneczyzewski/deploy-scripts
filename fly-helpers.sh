#!/bin/sh

# TODO: Inject these from Wasp CLI. The scripts assume `wasp build` has been called.
export WASP_PROJECT_DIR="/Users/shayne/dev/wasp/waspc/examples/todoApp"
export WASP_BUILD_DIR="$WASP_PROJECT_DIR/.wasp/build"
export WASP_APP_NAME="TodoApp"

# Check for Fly.io CLI.
checkForExecutable() {
  if ! command -v flyctl >/dev/null
  then
    echo "The Fly.io CLI is not available on this system."
    echo "Please install the flyctl here: https://fly.io/docs/hands-on/install-flyctl"
    exit
  fi
}

# Ensure the user is logged in.
ensureUserLoggedIn() {
  if ! flyctl auth whoami >/dev/null 2>/dev/null
  then
    printf "You are not logged in to flyctl. Would you like to login now (y/n)? "

    if isAnswerYes
    then
      echo "Launching login screen in your browser..."
    else
      echo "Exiting."
      exit
    fi

    if ! flyctl auth login
    then
      echo "It appears you are having trouble logggin in. Please try again."
      exit
    fi
  fi
}

# TODO: Improve this to retry if not y/n.
isAnswerYes() {
  read -r answer
  if [ "$answer" != "${answer#[Yy]}" ]; then
    return 0
  else
    return 1
  fi
}

# Creates the necessary Dockerfile for deploying static websites to Fly.io.
# Adds dummy .dockerignore to supress CLI question.
# Ref: https://fly.io/docs/languages-and-frameworks/static/
setupClientDocker() {
  dockerfile_contents="FROM pierrezemb/gostatic\nCOPY ./build/ /srv/http/"
  echo "$dockerfile_contents" > Dockerfile
  touch ".dockerignore"
}

server_toml_file_name="fly-server.toml"
export server_toml_file_name
server_toml_file_path="$WASP_PROJECT_DIR/$server_toml_file_name"
export server_toml_file_path
client_toml_file_name="fly-client.toml"
export client_toml_file_name
client_toml_file_path="$WASP_PROJECT_DIR/$client_toml_file_name"
export client_toml_file_path

copyTomlDownToCwd() {
  toml_file_path=$1
  cp "$toml_file_path" fly.toml
}

copyLocalTomlBackToProjectDir() {
  toml_file_path=$1
  cp -f fly.toml "$toml_file_path"
}

serverTomlExists() {
  test -f "$server_toml_file_path"
}

clientTomlExists() {
  test -f "$client_toml_file_path"
}

# Colors
YELLOW=$(tput setaf 3)
export YELLOW
RED=$(tput setaf 1)
export RED
CLEAR_FORMATTING="\e[0m"
export CLEAR_FORMATTING
SET_BOLD="\e[1m"
export SET_BOLD
UNSET_BOLD="\e[21m"
export UNSET_BOLD
