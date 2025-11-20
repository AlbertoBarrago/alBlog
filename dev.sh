#!/bin/bash
# Load environment variables from .env file and start Phoenix server

if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

iex -S mix phx.server
