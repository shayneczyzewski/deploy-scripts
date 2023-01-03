#!/bin/sh

# TODO: Accept and use args supplied after `wasp deploy fly [server|client] -- <flyctl-args>`
# TODO: Implement runServerCommand() and runClientCommand()

# TODO: Implement checkConfig()

# TODO: Inject these from Wasp CLI
export WASP_PROJECT_DIR="/Users/shayne/dev/wasp/waspc/examples/todoApp"
export WASP_BUILD_DIR="/Users/shayne/dev/wasp/waspc/examples/todoApp/.wasp/build"
export WASP_APP_NAME="foobar"

# Check for Fly.io CLI
checkForExecutable() {
  if ! command -v flyctl >/dev/null
  then
    echo "The Fly.io CLI is not available on this system."
    echo "Please install the flyctl here: https://fly.io/docs/hands-on/install-flyctl"
    exit
  fi
}

# Ensure the user is logged in
ensureUserLoggedIn() {
  if ! flyctl auth whoami >/dev/null 2>/dev/null
  then
    echo "You are not logged in to flyctl. Would you like to login now (y/n)?"
    read -r answer

    if [ "$answer" != "${answer#[Yy]}" ]
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

deployServer() {
  cd "$WASP_BUILD_DIR" || exit
  rm fly.toml

  if test -f "$WASP_PROJECT_DIR/fly-server.toml"; then
    echo "fly-server.toml file exists. Using for deployment."
    cp "$WASP_PROJECT_DIR/fly-server.toml" fly.toml

    if ! flyctl deploy
    then
      echo "Error deploying server."
      exit
    fi
  else
    echo "No fly-server.toml file exists. Does your app exist on Fly.io already (y/n)?"
    read -r answer

    if [ "$answer" != "${answer#[Yy]}" ]
    then
      flyctl apps list

      echo "What is your server app name?"
      read -r appName

      echo "Is $appName the correct server app name (y/n)?"
      read -r answer

      if [ "$answer" != "${answer#[Yy]}" ]
      then

        if flyctl config save -a "$appName"
        then
          echo "Saving server config."
          cp -f fly.toml "$WASP_PROJECT_DIR/fly-server.toml"
        else
          echo "Error saving server config."
          exit
        fi

        if ! flyctl deploy --remote-only
        then
          echo "Error deploying server."
          exit
        fi
      fi
    else
      echo "Launching a new Fly.io project."

      current_seconds=$(date +%s)
      fly_unique_name="wasp-$WASP_APP_NAME-$current_seconds" # TODO: Let user specify basename in future.
      server_name="$fly_unique_name-server"
      db_name="$fly_unique_name-db"
      client_name="$fly_unique_name-client"
      client_url="https://$client_name.fly.dev"

      # TODO: Handle errors somehow.
      flyctl launch --no-deploy --name "$server_name"
      cp -f fly.toml "$WASP_PROJECT_DIR/fly-server.toml"

      flyctl secrets set JWT_SECRET=todoChangeToRandomString PORT=8080 WASP_WEB_CLIENT_URL="$client_url"

      flyctl postgres create --name "$db_name"
      flyctl postgres attach "$db_name"
      flyctl deploy --remote-only

      echo "Your server has been deployed! Starting on client now..."
      launchClient server_name client_name
    fi
  fi
}

launchClient() {  
  server_name=$1
  client_name=$2

  echo "Launching client with name $client_name"

  cd "$WASP_BUILD_DIR/web-app" || exit
  rm fly.toml

  server_url="https://$server_name.fly.dev"

  npm install && REACT_APP_API_URL="$server_url" npm run build

  dockerfile_contents="FROM pierrezemb/gostatic\nCOPY ./build/ /srv/http/"
  echo "$dockerfile_contents" > Dockerfile
  cp -f "../.dockerignore" ".dockerignore"

  # TODO: Handle errors somehow.
  flyctl launch --no-deploy --name "$client_name"
  cp -f fly.toml "$WASP_PROJECT_DIR/fly-client.toml"

  # goStatic listens on port 8043 by default, but the default fly.toml assumes port 8080.
  cp fly.toml fly.toml.bak
  sed "s/= 8080/= 8043/1" fly.toml > fly.toml.new
  mv fly.toml.new fly.toml

  flyctl deploy --remote-only
}

ensureEnvarsSet() {
  true;
}

# Run it!!!!

echo "Let's deploy Wasp to Fly.io!"

checkForExecutable
ensureUserLoggedIn
deployServer
