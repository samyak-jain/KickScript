#!/bin/bash

# Define you config values here. 
# These variables are probably already configured on your backend as Environment Variables.
# So you can just copy and past them here.

# For BACKEND_URL, make sure to specify the URL along with /query
BACKEND_URL=

# This is the Agora App ID. You can look for the APP_ID environment variable on the backend
APP=

# You can configure them from environment variables CUSTOMER_ID and CUSTOMER_CERTIFICATE on the backend. 
# Or, you can get them from here: https://docs.agora.io/en/cloud-recording/faq/restful_authentication#implement-basic-http-authentication
CUSTOMER_ID=
CUSTOMER_SECRET=

# Function that will check if the given variables are empty or just contain whitespaces
check_empty () {
  case $2 in
    (*[![:space:]]*);;
    (*)
      echo "$1 is empty. Exiting..."
      exit 1
  esac
}

check_empty "BACKEND_URL" "$BACKEND_URL"
check_empty "APP" "$APP"
check_empty "CUSTOMER_ID" "$CUSTOMER_ID"
check_empty "CUSTOMER_SECRET" "$CUSTOMER_SECRET"

echo "Using AppID: $APP"
echo "Using Backend: $BACKEND_URL"
echo "Using Passphrase: $1"

# Make a request to the App Builder Backend to fetch the Agora Channel Name from the hash
channel=`curl -s --location --request POST "$BACKEND_URL" \
--header 'Content-Type: application/json' \
--data-raw '{"query":"query joinChannel ($passphrase: String!) {\n    joinChannel (passphrase: $passphrase) {\n        channel\n    }\n}","variables":{"passphrase":"'"$1"'"}}' | python3 -c "import sys, json; print(json.load(sys.stdin)['data']['joinChannel']['channel'])"`

echo "Using Channel Name: $channel"

echo ""
echo "WARNING: Using this script will ban everyone in this channel and no one will be able to join this channel for the specified time"

read -r -p "Are you sure? [y/N] " response

# Check if the response is yes (or any variant of yes). Otherwise, exit the program
if ! [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
then
  echo "Exiting Program..."
  exit 1
fi

# Use Agora's Kicking API to ban all users in the channel. 
# Customer ID and Customer Secret are used to authenticate using HTTP Basic Auth
curl -u $CUSTOMER_ID:$CUSTOMER_SECRET --location --request POST 'https://api.agora.io/dev/v1/kicking-rule' \
--header 'Content-Type: application/json' \
--data-raw '{
  "appid": "'"$APP"'",
  "cname": "'"$channel"'",
  "privileges": [
    "join_channel"
  ]
}'
