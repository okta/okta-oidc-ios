#!/bin/bash

# Set workspace
WORKSPACE="Okta.xcworkspace/"

# Set scheme
SCHEME="Okta-Example"

# Set test devices
IPHONE_X_DESTINATION="OS=11.2,name=iPhone X"

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
    -only-testing:Okta_Tests \
    USERNAME="$1" PASSWORD="$2" test | xcpretty;
}

build_and_run_ui_tests () {
    remove_simulator_data
    
    echo "└─  Starting UI Tests"
    
    set -o pipefail && xcodebuild -workspace "$WORKSPACE" -scheme "$SCHEME" \
    -destination "$IPHONE_X_DESTINATION" \
    -only-testing:Okta_UITests \
    USERNAME="$1" PASSWORD="$2" test | xcpretty;
}

remove_simulator_data () {
    echo "└─  Removing Simulator Data"
    xcrun simctl erase all
}
