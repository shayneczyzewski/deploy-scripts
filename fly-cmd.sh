#!/bin/sh

# TODO: Handle flyctl errors better.

# NOTE: This script itself should not be sourced for the following to work.
dir=$(cd -- "$(dirname -- "$0")" && pwd)
. "$dir/fly-helpers.sh" || exit

target="$1"
shift
args=$*

runServerCommand() {
  printf "\nRunning flyctl command in server context as follows: flyctl %s\n\n" "$args"

  if ! serverTomlExists
  then
    echo "$server_toml_file_name missing."
    exit
  fi

  cd "$WASP_BUILD_DIR" || exit
  copyTomlDownToCwd server_toml_file_path || exit

  # Run flyctl command with args provided by user.
  eval "flyctl $args" || exit

  copyLocalTomlBackToProjectDir "$server_toml_file_path" || exit
}

runClientCommand() {
  printf "\nRunning flyctl command in client context as follows: flyctl %s\n\n" "$args"

  if ! clientTomlExists
  then
    echo "$client_toml_file_name missing."
    exit
  fi

  cd "$WASP_BUILD_DIR/web-app" || exit
  copyTomlDownToCwd client_toml_file_path || exit

  # Run flyctl command with args provided by user.
  eval "flyctl $args" || exit

  copyLocalTomlBackToProjectDir "$client_toml_file_path" || exit
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
