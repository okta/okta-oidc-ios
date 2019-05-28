#!/bin/bash

# Set workspace
WORKSPACE="okta-oidc.xcworkspace/"

# Set scheme
SCHEME="okta-oidc"

# Set test devices
IPHONE_X_DESTINATION="OS=12.1,name=iPhone X"

pod_dependencies () {
    echo "- Installing dependencies"
    echo "└─  Installing pods"
    pod install --repo-update --silent
}

build_and_run_unit_tests () {
    remove_simulator_data

    echo "└─  Starting Unit Tests"

    set -o pipefail && xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
    -destination "$IPHONE_X_DESTINATION" \
    -only-testing:Okta_Tests test | xcpretty;
}

build_and_run_ui_tests () {
    remove_simulator_data

    echo "└─  Starting UI Tests"

    set -o pipefail && xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
    -destination "$IPHONE_X_DESTINATION" \
    -only-testing:Okta_UITests \
    USERNAME="$1" PASSWORD="$2" ISSUER="$3" REDIRECT_URI="$4" CLIENT_ID="$5" test | xcpretty;
}

remove_simulator_data () {
    echo "└─  Removing Simulator Data"
    xcrun simctl erase all
}
