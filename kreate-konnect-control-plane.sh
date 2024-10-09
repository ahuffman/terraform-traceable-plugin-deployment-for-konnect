#! /usr/bin/env bash

# ACCESS_TOKEN=""
# Collect Personal Access Token from user
read -p "Enter your Kong Konnect Personal Access Token: " ACCESS_TOKEN

CP_NAME="traceable-kong-workshop"
CP_DESCRIPTION="Control Plane for Kong and Traceable workshop"
URL="https://us.api.konghq.com"
APIVERSION="v2"
KONG_OUT="./kong_out"
CERT_PATH="./tls.crt"

RETRY=0
function create_control_plane () {
  RETRY=$((RETRY+1))
  echo "Ensuring specified Kong Konnect control-plane exists in Kong Konnect..."
  CONTROL_PLANE=`curl -s -o /dev/null  -w "%{http_code}" -X POST "$URL/$APIVERSION/control-planes/" \
       --header "Authorization: Bearer $ACCESS_TOKEN" \
       --header 'Content-Type: application/json' \
       --header 'accept: application/json' \
       --data "{\"name\":\"$CP_NAME\",\"description\":\"$CP_DESCRIPTION\"}" -i`

  while [[ "$CONTROL_PLANE" != "409" ]] && [[ "$CONTROL_PLANE" != "201" ]]; do
      if [ $RETRY -lt 3 ]; then
        printf "Bad response: '$CONTROL_PLANE' is not '201' or '409'.\n"
        printf "Sleeping 10 seconds before retrying.\n\n"
        sleep 10
        create_control_plane
      else
        printf "Failed to provision control plane.  Received $CONTROL_PLANE from Kong Konnect API, exiting...\n\n"
        exit 1
      fi
  done

  if [ "$CONTROL_PLANE" == "409" ]; then
      printf "Kong Konnect Control Plane '$CP_NAME' exists.\n\n"
  elif [ "$CONTROL_PLANE" == "201" ]; then
      printf "Kong Konnect Control Plane '$CP_NAME' was created!\n\n"
  fi
}


function get_control_planes () {
  printf "Collecting Kong Konnect control plane data...\n"
  DATA=`curl -s --get \
         --data-urlencode "filter[name][eq]=$CP_NAME" \
         --header "Authorization: Bearer $ACCESS_TOKEN" \
         --header 'Content-Type: application/json' \
         --header 'accept: application/json' \
         $URL/$APIVERSION/control-planes`

  KONG_CP_ID=`echo $DATA | jq .data[0].id | sed -e 's/\"//g'`

  KONG_CP_URL=`echo $DATA | jq .data[0].config.control_plane_endpoint | sed -e 's/https:\/\///' | sed -e 's/\"//g'`
  echo "cluster_control_plane=$KONG_CP_URL:443" > $KONG_OUT
  echo "cluster_server_name=$KONG_CP_URL" >> $KONG_OUT

  KONG_TELEMETRY_URL=`echo $DATA | jq .data[0].config.telemetry_endpoint | sed -e 's/https:\/\///' | sed -e 's/\"//g'`
  echo "cluster_telemetry_endpoint=$KONG_TELEMETRY_URL:443" >> $KONG_OUT
  echo "cluster_telemetry_server_name=$KONG_TELEMETRY_URL" >> $KONG_OUT
  # For Terraform plugin support - Step 2
  echo "konnect_cp_id=$KONG_CP_ID" >> $KONG_OUT
  echo "konnect_pat=$ACCESS_TOKEN" >> $KONG_OUT
  printf "Success!\n\n"
}


function push_konnect_gw_certificate () {
  CERT=$(awk '{printf "%s\\r\\n", $0}' $CERT_PATH)
  echo "Attempting to push certificate to the Kong Konnect control plane..."
  CP_CERT=`curl -s -o /dev/null -w "%{http_code}" --request POST \
             --url "$URL/$APIVERSION/control-planes/$KONG_CP_ID/dp-client-certificates" \
             --header "Authorization: Bearer $ACCESS_TOKEN" \
             --header "Content-Type: application/json" \
             --header "accept: application/json" \
             --data "{\"cert\":\"${CERT}\"}"
  `
  if [ "$CP_CERT" == "201" ]; then
    printf "Kong Konnect dataplane certificate has been successfully pushed to the control plane!\n\n"
  else
    echo "Failed to push Kong Konnect certificate to control plane, exiting..."
    exit 1
  fi
}


# Ensure specified Kong Konnect control plane exists
create_control_plane

# Collect required Kong Konnect control plane data and create environment vars script
get_control_planes

# Push Kong Konnect gateway instance certificate to Kong Konnect control plane
if [ ! "x$CERT_PATH" = "x" ]; then
  push_konnect_gw_certificate
else
  printf "No Kong Konnect dataplane certificate to push...skipping\n\n"
fi

printf "Control Plane settings for Dataplane configuration:\n\n"
cat $KONG_OUT

printf "\n\nSuccessfully provisioned Kong Konnect Control Plane!\n\n"
printf "Done!\n"
exit 0