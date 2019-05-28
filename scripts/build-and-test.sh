#!/bin/bash
source "${0%/*}/helpers.sh"

set -e

echo "- Starting tests..."

if ! build_and_run_ui_tests "$USERNAME" "$PASSWORD" "$ISSUER" "$REDIRECT_URI" "$CLIENT_ID" "$LOGOUT_REDIRECT_URI"; then
    exit 1
else
    echo -e "\xE2\x9C\x94 Passed UI tests"
fi

if ! build_and_run_unit_tests "$USERNAME" "$PASSWORD" "$ISSUER" "$REDIRECT_URI" "$CLIENT_ID" "$LOGOUT_REDIRECT_URI"; then
    exit 1
else
    echo -e "\xE2\x9C\x94 Passed Unit tests"
fi
