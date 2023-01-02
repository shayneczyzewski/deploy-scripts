#!/bin/sh

# Check for Fly.io CLI
if ! command -v flyctl >/dev/null
then
  echo "The Fly.io CLI is not installed on this system. Please install the flyctl here: https://fly.io/docs/hands-on/install-flyctl"
  exit
fi

# Ensure the user is logged in
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
