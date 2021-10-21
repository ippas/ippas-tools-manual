#!/usr/bin/env bash


TOOLS_DIR="/net/archive/groups/plggneuromol/tools/"
IMAGE="ratelimitpreview/test"

# obtain a token for authorization
TOKEN=$(curl -s "https://auth.docker.io/token?service=registry.docker.io&scope=repository:$IMAGE:pull" | \
    $TOOLS_DIR/jq -r .token)

# simulate a docker pull request
RESPONSE=$(curl -s --head -H "Authorization: Bearer $TOKEN" \
    https://registry-1.docker.io/v2/$IMAGE/manifests/latest)
RESPONSE_LIMIT=$(echo "$RESPONSE" | sed -rn "s/ratelimit-remaining:\s+([0-9]+).*/\1/p")

echo "$RESPONSE_LIMIT"
