#!/bin/sh

# TODO: Handle flyctl errors better.

# NOTE: This script itself should not be sourced for the following to work.
dir=$(cd -- "$(dirname -- "$0")" && pwd)
. "$dir/fly-helpers.sh" || exit

deployWaspApp() {
  if ! serverTomlExists
  then
    echo "$server_toml_file_name missing. Skipping server deploy. Do you want to launch instead?"
  else
    deployServer
  fi

  if ! clientTomlExists
  then
    echo "$client_toml_file_name missing. Skipping client deploy. Do you want to launch instead?"
  else
    deployClient
  fi
}

deployServer() {
  echo "Deploying server..."

  cd "$WASP_BUILD_DIR" || exit
  copyTomlDownToCwd "$server_toml_file_path" || exit

  flyctl deploy --remote-only || exit

  echo "Your server has been deployed!"
}

deployClient() {
  echo "Deploying client..."

  cd "$WASP_BUILD_DIR/web-app" || exit
  copyTomlDownToCwd "$client_toml_file_path"|| exit

  # Infer names from client fly.toml file.
  client_name=$(grep "app =" $client_toml_file_path | cut -d '"' -f2)
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
