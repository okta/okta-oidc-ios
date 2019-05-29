#!/bin/bash

# Set workspace
WORKSPACE="okta-oidc.xcworkspace/"

# Set scheme
SCHEME="okta-oidc"

# Set test devices
IPHONE_X_DESTINATION="OS=12.1,name=iPhone X"

build_and_run_unit_tests () {
    remove_simulator_data

    echo "└─  Starting Unit Tests"

    set -o pipefail && xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
    -destination "$IPHONE_X_DESTINATION" \
    -only-testing:OktaOidcTests test | xcpretty;
}

build_and_run_ui_tests () {
    remove_simulator_data

    echo "└─  Starting UI Tests"

    set -o pipefail && xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
    -destination "$IPHONE_X_DESTINATION" \
    -only-testing:OktaOidcUITests \
    USERNAME="$1" PASSWORD="$2" ISSUER="$3" REDIRECT_URI="$4" CLIENT_ID="$5" LOGOUT_REDIRECT_URI="$6" test | xcpretty;
}

remove_simulator_data () {
    echo "└─  Removing Simulator Data"
    xcrun simctl erase all
}
