#!/bin/sh

# TODO: Inject these from Wasp CLI. The scripts assume `wasp build` has been called.
export WASP_PROJECT_DIR="/Users/shayne/dev/wasp/waspc/examples/todoApp"
export WASP_BUILD_DIR="$WASP_PROJECT_DIR/.wasp/build"
export WASP_APP_NAME="foobar"

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

# Colors
YELLOW=$(tput setaf 3)
RED=$(tput setaf 1)
CLEAR_FORMATTING="\e[0m"
SET_BOLD="\e[1m"
UNSET_BOLD="\e[21m"