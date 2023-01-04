#!/bin/sh

# TODO: Handle flyctl errors better.

# NOTE: This script itself should not be sourced for the following to work.
dir=$(cd -- "$(dirname -- "$0")" && pwd)
. "$dir/fly-helpers.sh" || exit

deployWaspApp() {
  if ! test -f "$WASP_PROJECT_DIR/fly-server.toml"
  then
    echo "fly-server.toml missing. Skipping server deploy. Do you want to launch instead?"
  else
    deployServer
  fi

  if ! test -f "$WASP_PROJECT_DIR/fly-client.toml"
  then
    echo "fly-client.toml missing. Skipping client deploy. Do you want to launch instead?"
  else
    deployClient
  fi
}

deployServer() {
  echo "Deploying server..."

  cd "$WASP_BUILD_DIR" || exit
  cp "$WASP_PROJECT_DIR/fly-server.toml" fly.toml || exit

  flyctl deploy --remote-only || exit

  echo "Your server has been deployed!"
}

deployClient() {
  echo "Deploying client..."

  cd "$WASP_BUILD_DIR/web-app" || exit
  cp "$WASP_PROJECT_DIR/fly-client.toml" fly.toml || exit

  # Infer names from fly-server.toml file.
  client_name=$(grep "app =" $WASP_PROJECT_DIR/fly-client.toml | cut -d '"' -f2)
  server_name=$(echo "$client_name" | sed 's/-client$/-server/')
  client_url="https://$client_name.fly.dev"
  server_url="https://$server_name.fly.dev"

  echo "Building web client for production..."

  npm install || exit
  REACT_APP_API_URL="$server_url" npm run build || exit

  setupClientDocker

  flyctl deploy --remote-only || exit

  echo "Your client has been deployed! Your Wasp app is accessible at $client_url"
}

echo "Deploying your Wasp app to Fly.io!"

checkForExecutable
ensureUserLoggedIn
deployWaspApp
