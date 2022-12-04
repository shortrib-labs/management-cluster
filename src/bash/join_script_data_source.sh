#!/usr/bin/env bash
jq -n --arg join "$(curl -sL https://kurl.sh/latest/tasks.sh | sudo bash -s join_token | tail -3 | head -1 | sed -e "s/\x1b\[.\{1,5\}m//g" -e "s/^[[:space:]]*//g")" '{ "script": $join }'
