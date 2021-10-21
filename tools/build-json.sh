#!/usr/bin/env bash

# Prepare curl data request for job submitting


SCRIPT="$1
$2
"

WD=$3
TOOLS_DIR="/net/archive/groups/plggneuromol/tools/"

$TOOLS_DIR/jq -n \
    --arg script "$SCRIPT" \
    --arg host "pro.cyfronet.pl" \
    --arg working_directory "$WD" \
    '{ host : $host, script : $script, working_directory : $working_directory }'
