#!/bin/bash

set -e

# Go to correct path for install
cd Example


function pod_install() {
    echo "==== Installing pods ===="
    pod install
}

if ! pod_install; then
    exit 1
fi

function build_and_test_workspace() {
    echo "*******************"
    echo "Building Workspace"
    echo "*******************"
    xcodebuild test \
    -workspace Okta.xcworkspace/ \
    -scheme Okta-Example \
    -destination 'platform=iOS Simulator,OS=10.3.1,name=iPhone 7' \
    -only-testing:Okta_Tests
}

if ! build_and_test_workspace; then
    exit 1
fi

echo "All tests passed"
