#!/bin/sh

# TODO: Handle flyctl errors better.

# TODO: Inject these from Wasp CLI.
export WASP_PROJECT_DIR="/Users/shayne/dev/wasp/waspc/examples/todoApp"
export WASP_BUILD_DIR="/Users/shayne/dev/wasp/waspc/examples/todoApp/.wasp/build"
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

# Get the preferred region from the user.
region=""
getRegion() {
  if [ "$region" = "" ]
  then
    echo ""

    flyctl platform regions || exit

    printf "\nIn what region above would you like to launch your Wasp app?"
    printf "\nPlease input the three letter code: "

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

launchWaspApp() {
  if test -f "$WASP_PROJECT_DIR/fly-server.toml"
  then
    echo "fly-server.toml exists. Skipping server launch."

    if test -f "$WASP_PROJECT_DIR/fly-client.toml"
    then
      echo "fly-client.toml exists. Skipping client launch."
    else
      # Infer names from fly-server.toml file.
      server_name=$(grep "app =" $WASP_PROJECT_DIR/fly-server.toml | cut -d '"' -f2)
      client_name=$(echo "$server_name" | sed 's/-server$/-client/')

      launchClient "$server_name" "$client_name"
    fi
  else
    launchServer
  fi
}

launchServer() {
  current_seconds=$(date +%s)
  sample_basename="wasp-$WASP_APP_NAME-$current_seconds"
  
  echo "What would you like your app basename to be called? For example: $sample_basename"
  echo "We use this name to construct the others, like $sample_basename-server, $sample_basename-db, and $sample_basename-client."
  echo "Note: This must be unique across all of Fly.io. If it is a duplicate, the deploy will be aborted. Please consider using a long name with letters and numbers."

  printf "Desired basename: "
  read -r desired_basename

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
  cp -f fly.toml "$WASP_PROJECT_DIR/fly-server.toml"

  # TODO: todoChangeToRandomString
  flyctl secrets set JWT_SECRET=todoChangeToRandomString PORT=8080 WASP_WEB_CLIENT_URL="$client_url" || exit

  flyctl postgres create --name "$db_name" --region "$region" || exit
  flyctl postgres attach "$db_name" || exit
  flyctl deploy --remote-only || exit

  echo "Your server has been deployed! Starting on client now..."
  launchClient "$server_name" "$client_name"
}

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

  npm install && REACT_APP_API_URL="$server_url" npm run build

  dockerfile_contents="FROM pierrezemb/gostatic\nCOPY ./build/ /srv/http/"
  echo "$dockerfile_contents" > Dockerfile
  cp -f "../.dockerignore" ".dockerignore"

  flyctl launch --no-deploy --name "$client_name" --region "$region" || exit

  # goStatic listens on port 8043 by default, but the default fly.toml assumes port 8080.
  cp fly.toml fly.toml.bak
  sed "s/= 8080/= 8043/1" fly.toml > fly.toml.new
  mv fly.toml.new fly.toml

  cp -f fly.toml "$WASP_PROJECT_DIR/fly-client.toml"

  flyctl deploy --remote-only || exit

  echo "Congratulations! Your Wasp app is now accessible at $client_url"
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

echo "Launching your Wasp app to Fly.io!"

checkForExecutable
ensureUserLoggedIn
launchWaspApp
