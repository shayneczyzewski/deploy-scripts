#!/bin/sh

# TODO: Handle flyctl errors better.

# NOTE: This script itself should not be sourced for the following to work.
dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
. "$dir/fly-helpers.sh" || exit

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

echo "Deploying your Wasp app to Fly.io!"

checkForExecutable
ensureUserLoggedIn
deployWaspApp
