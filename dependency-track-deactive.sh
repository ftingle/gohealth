#!/usr/bin/env bash

set -ue
set -o pipefail

function log(){
    local date
    local loc
    date=$(date -u +"%m-%d-%yT%H:%m:%SZ")
    loc="$(basename "${0}"):${BASH_LINENO[0]}"
    echo -e "${date} ${loc} - $1"
}

if ! type -P curl &> /dev/null; then
    log "ERROR: curl is not installed on the system."
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

log "Getting UUID for project '${name}:${version}'..."
uuid=$(curl --silent --fail -H "X-Api-Key: ${API_TOKEN}" "${DT_URL_V1}/project/lookup?name=${name}&version=${version}" | jq -r .uuid)

log "Deactivating project '${name}:${version}' with UUID '${uuid}'..."
active=$(curl --silent --fail -X PATCH -H "X-Api-Key: ${API_TOKEN}" -H 'content-type: application/json' --data '{"active": false}' "${DT_URL_V1}/project/${uuid}" | jq .active)

log "The active status is set to '${active}', done."