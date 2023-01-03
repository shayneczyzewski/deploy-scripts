#!/bin/sh

# TODO: Handle flyctl errors better.

# TODO: Inject these from Wasp CLI.
export WASP_PROJECT_DIR="/home/shayne/dev/wasp/waspc/examples/todoApp"
export WASP_BUILD_DIR="/home/shayne/dev/wasp/waspc/examples/todoApp/.wasp/build"
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

deployWaspApp() {
  if ! test -f "$WASP_PROJECT_DIR/fly-server.toml"
  then
    echo "fly-server.toml missing. Skipping server deploy. Try resyncing or launching instead."
  else
    deployServer
  fi
}

deployServer() {
  cd "$WASP_BUILD_DIR" || exit
  cp -f "$WASP_PROJECT_DIR/fly-server.toml" fly.toml

  flyctl deploy --remote-only || exit

  echo "Your server has been deployed!"
}

deployClient() {
  # TODO
  true;
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

echo "Deploying your Wasp app to Fly.io!"

checkForExecutable
ensureUserLoggedIn
deployWaspApp
