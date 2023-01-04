#!/bin/sh

# TODO: Handle flyctl errors better.

# NOTE: This script itself should not be sourced for the following to work.
dir=$(cd -- "$(dirname -- "$0")" && pwd)
. "$dir/fly-helpers.sh" || exit

target="$1"
shift
args=$*

runServerCommand() {
  printf "\nRunning flyctl command in server context as follows: flyctl $args\n\n"

  if ! test -f "$WASP_PROJECT_DIR/fly-server.toml"
  then
    echo "fly-server.toml missing."
    exit
  fi

  cd "$WASP_BUILD_DIR" || exit
  cp "$WASP_PROJECT_DIR/fly-server.toml" fly.toml || exit

  # Run flyctl command with args provided by user.
  eval "flyctl $args" || exit

  cp -f fly.toml "$WASP_PROJECT_DIR/fly-server.toml"
}

runClientCommand() {
  printf "\nRunning flyctl command in client context as follows: flyctl $args\n\n"

  if ! test -f "$WASP_PROJECT_DIR/fly-client.toml"
  then
    echo "fly-client.toml missing."
    exit
  fi

  cd "$WASP_BUILD_DIR/web-app" || exit
  cp "$WASP_PROJECT_DIR/fly-client.toml" fly.toml || exit

  # Run flyctl command with args provided by user.
  eval "flyctl $args" || exit

  cp -f fly.toml "$WASP_PROJECT_DIR/fly-client.toml"
}

checkForExecutable
ensureUserLoggedIn

if [ "$target" = "server" ]
then
  runServerCommand
fi

if [ "$target" = "client" ]
then
  runClientCommand
fi
