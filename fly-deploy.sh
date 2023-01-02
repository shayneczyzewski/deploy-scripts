#!/bin/sh

# TODO: Accept and use args supplied after `wasp deploy fly -- [server|client] <flyctl-args>`
# TODO: Implement runServerCommand() and runClientCommand()

# TODO: Implement checkConfig()

# TODO: Inject these from Wasp CLI
export WASP_PROJECT_DIR="/Users/shayne/dev/wasp/waspc/examples/todoApp"
export WASP_BUILD_DIR="/Users/shayne/dev/wasp/waspc/examples/todoApp/.wasp/out"
export WASP_APP_NAME="foobar"

# Check for Fly.io CLI
checkForExecutable() {
  if ! command -v flyctl >/dev/null
  then
    echo "The Fly.io CLI is not installed on this system. Please install the flyctl here: https://fly.io/docs/hands-on/install-flyctl"
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
  cd "$WASP_BUILD_DIR/server" || exit
  rm "fly.toml"

  if test -f "$WASP_PROJECT_DIR/fly-server.toml"; then
    echo "fly-server.toml file exists. Using for deployment."
    cp "$WASP_PROJECT_DIR/fly-server.toml" "fly.toml"

    if ! flyctl deploy
    then
      echo "Error deploying server."
      exit
    fi
  else
    echo "No fly-server.toml file exists. Does your project exist on Fly.io already (y/n)?"
    read -r answer

    if [ "$answer" != "${answer#[Yy]}" ]
    then
      flyctl apps list

      echo "What is your server project name?"
      read -r projectName

      echo "Is $projectName the correct server project name (y/n)?"
      read -r answer

      if [ "$answer" != "${answer#[Yy]}" ]
      then

        if flyctl config save -a "$projectName"
        then
          echo "Saving server config."
          cp -f "fly.toml" "$WASP_PROJECT_DIR/fly-server.toml"
        else
          echo "Error saving server config."
          exit
        fi

        if ! flyctl deploy
        then
          echo "Error deploying server."
          exit
        fi
      fi
    else
      echo "Launching new Fly.io project..."

      if flyctl launch --remote-only
      then
        cp -f "fly.toml" "$WASP_PROJECT_DIR/fly-server.toml"
      else
        echo "There was a problem launching the server. Please check your Fly.io dashboard."
        exit
      fi
    fi
  fi
}

deployClient() {
  true;
}

ensureEnvarsSet() {
  true;
}

# Run it!!!!

echo "Let's deploy Wasp to Fly.io!"

checkForExecutable
ensureUserLoggedIn
deployServer
