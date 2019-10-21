#!/bin/bash

# Color Constants
RED_COLOR=`tput setaf 1`
GREEN_COLOR=`tput setaf 2`
YELLOW_COLOR=`tput setaf 3`
CLEAR_COLOR=`tput sgr 0`

# Check Errors
checkError() {
  if [ $1 -ne 0 ]; then
    echo "🔥  ${RED_COLOR}There are some error. See log above.${CLEAR_COLOR}"
    exit 1
  fi
}

# Check uncommited changes
require_clean_work_tree() {
    # Update the index
    git update-index -q --ignore-submodules --refresh
    err=0

    # Disallow unstaged changes in the working tree
    if ! git diff-files --quiet --ignore-submodules --
    then
        echo >&2 "${YELLOW_COLOR}You have unstaged changes.${CLEAR_COLOR}"
        git diff-files --name-status -r --ignore-submodules -- >&2
        err=1
    fi

    # Disallow uncommitted changes in the index
    if ! git diff-index --cached --quiet HEAD --ignore-submodules --
    then
        echo >&2 "${YELLOW_COLOR}Your index contains uncommitted changes.${CLEAR_COLOR}"
        git diff-index --cached --name-status -r --ignore-submodules HEAD -- >&2
        err=1
    fi

    if [ $err = 1 ]
    then
        echo >&2 "${YELLOW_COLOR}Please commit or stash them before running this script.${CLEAR_COLOR}"
        exit 1
    fi
}

# Check uncommited changes
echo "Checking uncommited changes..."
require_clean_work_tree
checkError $?

echo "Cleanning react-native poop..."

# Removes all watches and associated triggers
watchman watch-del-all
checkError $?

# Remove iOS build directory
rm -rf ios/build
checkError $?

# Remove node_modules directory
rm -rf node_modules
checkError $?

# Remove temp directory
rm -rf $TMPDIR/react-*
rm -rf $TMPDIR/haste-map-react-native-packager-*

## Clear yarn cache
yarn cache clean
checkError $?

# Install 3rd Party
echo "Installing 3rd party packages..."
yarn install
checkError $?

# Link native dependencies
echo "Linking packages..."
react-native link
checkError $?

# Reset git head
echo "Reseting git HEAD..."
git reset HEAD --hard
checkError $?

# Install iOS 3rd party dependencies
echo "Installing pods..."
cd ios
checkError $?
pod install
checkError $?
cd ..

echo "🎉  ${GREEN_COLOR}Everything looks great. Now run ${YELLOW_COLOR}react-native start -- --reset-cache${GREEN_COLOR} in your terminal.${CLEAR_COLOR}"