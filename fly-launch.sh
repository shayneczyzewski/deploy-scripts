#!/bin/sh
# shellcheck disable=SC2059

# TODO: Handle flyctl errors better.

# NOTE: This script itself should not be sourced for the following to work.
dir=$(cd -- "$(dirname -- "$0")" && pwd)
. "$dir/fly-helpers.sh" || exit

# Get the preferred region from the user.
region=""
getRegion() {
  if [ "$region" = "" ]
  then
    echo ""

    flyctl platform regions || exit

    printf "\nIn what region above would you like to launch your Wasp app?"
    printf "$SET_BOLD"
    printf "\n\nPlease input the three letter code: "
    printf "$CLEAR_FORMATTING"

    read -r selected_region

    printf "Is %s correct (y/n)? " "$selected_region"

    if isAnswerYes
    then
      region="$selected_region"
      echo ""
    else
      exit
    fi
  fi
}

# Decides if we should launch the server/client based on toml file existence.
launchWaspApp() {
  if serverTomlExists
  then
    echo "$server_toml_file_name exists. Skipping server launch."

    if clientTomlExists
    then
      echo "$client_toml_file_name exists. Skipping client launch."
    else
      # Infer names from server fly.toml file.
      server_name=$(grep "app =" $server_toml_file_path | cut -d '"' -f2)
      client_name=$(echo "$server_name" | sed 's/-server$/-client/')

      launchClient "$server_name" "$client_name"
    fi
  else
    launchServer
  fi
}

# Launches the server in a user-specified region, using a user-specified app base name.
# The app base name is used for db and client as well.
launchServer() {
  current_seconds=$(date +%s)
  sample_basename="wasp-$WASP_APP_NAME-$current_seconds"
  
  printf "\nWhat would you like your app basename to be called? For example: $YELLOW $sample_basename $CLEAR_FORMATTING"
  printf "\nWe use this name to construct the others, like %s" "$sample_basename-server, $sample_basename-db, and $sample_basename-client."
  printf "\nNote: This must be unique across all of Fly.io. If it is a duplicate, the deploy will be aborted. Please consider using a long name with letters and numbers."

  printf "$SET_BOLD"
  printf "\n\nDesired basename: "
  read -r desired_basename

  printf "$CLEAR_FORMATTING"
  printf "Is %s correct (y/n)? " "$desired_basename"

  if ! isAnswerYes
  then
    exit
  fi

  server_name="$desired_basename-server"
  db_name="$desired_basename-db"
  client_name="$desired_basename-client"
  client_url="https://$client_name.fly.dev"

  echo "Launching server with name $server_name"

  getRegion

  cd "$WASP_BUILD_DIR" || exit
  rm -f fly.toml

  flyctl launch --no-deploy --name "$server_name" --region "$region" || exit
  copyLocalTomlBackToProjectDir "$server_toml_file_path" || exit

  random_string=$(od -x /dev/urandom | head -1 | awk '{print $2$3$4$5$6$7$8$9}')
  flyctl secrets set JWT_SECRET="$random_string" PORT=8080 WASP_WEB_CLIENT_URL="$client_url" || exit

  flyctl postgres create --name "$db_name" --region "$region" || exit
  flyctl postgres attach "$db_name" || exit
  flyctl deploy --remote-only || exit

  echo "Your server has been deployed! Starting on client now..."
  launchClient "$server_name" "$client_name"
}

# Launches client with provided server/client names.
launchClient() {  
  server_name=$1
  client_name=$2

  echo "Launching client with name $client_name"

  getRegion

  cd "$WASP_BUILD_DIR/web-app" || exit
  rm -f fly.toml

  server_url="https://$server_name.fly.dev"
  client_url="https://$client_name.fly.dev"

  echo "Building web client for production..."

  npm install || exit
  REACT_APP_API_URL="$server_url" npm run build || exit

  setupClientDocker

  flyctl launch --no-deploy --name "$client_name" --region "$region" || exit

  # goStatic listens on port 8043 by default, but the default fly.toml assumes port 8080.
  cp fly.toml fly.toml.bak
  sed "s/= 8080/= 8043/1" fly.toml > fly.toml.new
  mv fly.toml.new fly.toml

  copyLocalTomlBackToProjectDir "$client_toml_file_path" || exit

  flyctl deploy --remote-only || exit

  echo "Congratulations! Your Wasp app is now accessible at $client_url"
}

echo "Launching your Wasp app to Fly.io!"

checkForExecutable
ensureUserLoggedIn
launchWaspApp
