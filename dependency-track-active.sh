#!/usr/bin/env bash

set -u
set -o pipefail

function log(){
    local date
    local loc
    date=$(date -u +"%m-%d-%yT%H:%m:%SZ")
    loc="$(basename "${0}"):${BASH_LINENO[0]}"
    echo -e "${date} ${loc} - $1"
}

if ! type -P curl &> /dev/null; then
    log "ERROR: curl is not installed on the system. curl must be installed in order for the build to run."
    exit 1
fi

if ! type -P jq &> /dev/null; then
    log "ERROR: jq is not installed on the system."
    exit 1
fi

DT_URL_V1="https://dependency-track-api.ops-test.gohealth.net/api/v1"
API_TOKEN="WoC9Zdr2eNDlhaiTKJm69ViX1TJIFNiV"

name=$1
version=$2
env=$3

log "Getting the information about project '${name}' which is currently marked with '${env}' tag..."
project=$(curl --silent --fail -H "X-Api-Key: ${API_TOKEN}" "${DT_URL_V1}/project/tag/${env}" | jq -r ".[] | select(.name == \"${name}\")")
uuid=$(jq -r .uuid <<< "$project")
tags=$(jq -r -c ".tags | map(. | select(.name != \"${env}\"))" <<< "$project")

log "Deactivating the current '${name}' project and removing '${env}' tag for project with UUID '${uuid}'..."
active=$(curl --silent --fail -X PATCH -H "X-Api-Key: ${API_TOKEN}" -H 'content-type: application/json' --data "{\"active\": false, \"tags\": ${tags}}" "${DT_URL_V1}/project/${uuid}" | jq .active)
log "The attribute 'active' for project with '${uuid}' UUID is set to '${active}' - Done!"

log "Getting the information about project '${name}:${version}' which is going to be marked with '${env}' tag..."
uuid=$(curl --silent --fail -H "X-Api-Key: ${API_TOKEN}" "${DT_URL_V1}/project/lookup?name=${name}&version=${version}" | jq -r .uuid)
tags="[{\"name\":\"${version}\"}, {\"name\":\"${env}\"}]"

log "Activating project '${name}:${version}' with UUID '${uuid}' and set '${env} tag'..."
active=$(curl --silent --fail -X PATCH -H "X-Api-Key: ${API_TOKEN}" -H 'content-type: application/json' --data "{\"active\": true, \"tags\": ${tags}}" "${DT_URL_V1}/project/${uuid}"| jq .active)
log "The attribute 'active' for project with '${uuid}' UUID is set to '${active}' - Done!"