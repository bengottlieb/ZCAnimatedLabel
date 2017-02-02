#!/bin/sh

#  BuildFramework.sh
#  FrameworkTest
#
#  Created by Ben Gottlieb on 1/21/15.
#  Copyright (c) 2015 Stand Alone, Inc. All rights reserved.

FRAMEWORK_NAME="AnimatedLabel"
BASE_BUILD_DIR=${BUILD_DIR}
IOS_SUFFIX=""
UNIVERSAL_OUTPUTFOLDER="Build/${CONFIGURATION}-universal"
echo ${BASE_BUILD_DIR}

rm -r ${BASE_BUILD_DIR}

GIT_BRANCH=`git branch --no-color 2> /dev/null | sed -e '/^[^*]/d' -e "s/* \(.*\)/\1/"`
GIT_REV=`git rev-parse --short HEAD`

BUILD_DATE=`date`

IOS_PLIST_PATH="${PROJECT_DIR}/AnimatedLabel/info.plist"
$(/usr/libexec/PlistBuddy "${IOS_PLIST_PATH}" -c "Delete :branch" 2> /dev/null)
$(/usr/libexec/PlistBuddy "${IOS_PLIST_PATH}" -c "Delete :rev" 2> /dev/null)
$(/usr/libexec/PlistBuddy "${IOS_PLIST_PATH}" -c "Delete :built" 2> /dev/null)
/usr/libexec/PlistBuddy "${IOS_PLIST_PATH}" -c "Add :branch string ${GIT_BRANCH}"
/usr/libexec/PlistBuddy "${IOS_PLIST_PATH}" -c "Add :rev string ${GIT_REV}"
/usr/libexec/PlistBuddy "${IOS_PLIST_PATH}" -c "Add :built string ${BUILD_DATE}"

# make sure the output directory exists
mkdir -p "${UNIVERSAL_OUTPUTFOLDER}"

# Step 1. Build Device and Simulator versions
xcodebuild -target "AnimatedLabel" -configuration ${CONFIGURATION} -sdk iphoneos ONLY_ACTIVE_ARCH=NO  BUILD_DIR="${BASE_BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build
xcodebuild -target "AnimatedLabel" -configuration ${CONFIGURATION} -sdk iphonesimulator ONLY_ACTIVE_ARCH=NO BUILD_DIR="${BASE_BUILD_DIR}" BUILD_ROOT="${BUILD_ROOT}" clean build

sleep 1s

# Step 2. Copy the framework structure (from iphoneos build) to the universal folder
echo "copying device framework"
cp -R "${BASE_BUILD_DIR}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}${IOS_SUFFIX}.framework" "${UNIVERSAL_OUTPUTFOLDER}/"

# Step 3. Copy Swift modules (from iphonesimulator build) to the copied framework directory
echo "integrating sim framework"
cp -R "${BASE_BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}${IOS_SUFFIX}.framework/Modules/${FRAMEWORK_NAME}${IOS_SUFFIX}.swiftmodule/" "${UNIVERSAL_OUTPUTFOLDER}/${FRAMEWORK_NAME}${IOS_SUFFIX}.framework/Modules/${FRAMEWORK_NAME}${IOS_SUFFIX}.swiftmodule/"

# Step 4. Create universal binary file using lipo and place the combined executable in the copied framework directory
echo "lipo'ing files"
lipo -create -output "${UNIVERSAL_OUTPUTFOLDER}/${FRAMEWORK_NAME}${IOS_SUFFIX}.framework/${FRAMEWORK_NAME}${IOS_SUFFIX}" "${BASE_BUILD_DIR}/${CONFIGURATION}-iphonesimulator/${FRAMEWORK_NAME}${IOS_SUFFIX}.framework/${FRAMEWORK_NAME}${IOS_SUFFIX}" "${BASE_BUILD_DIR}/${CONFIGURATION}-iphoneos/${FRAMEWORK_NAME}${IOS_SUFFIX}.framework/${FRAMEWORK_NAME}${IOS_SUFFIX}"

echo "copying to iOS Framework folder"
# Step 5. Convenience step to copy the framework to the project's directory
mkdir -p "${PROJECT_DIR}/iOS Framework/"
rm -rf "${PROJECT_DIR}/iOS Framework/${FRAMEWORK_NAME}${IOS_SUFFIX}.framework"
cp -R "${UNIVERSAL_OUTPUTFOLDER}/${FRAMEWORK_NAME}${IOS_SUFFIX}.framework" "${PROJECT_DIR}/iOS Framework"

if [ ! -d "${IOS_FRAMEWORKS}" ]; then
	mkdir "${IOS_FRAMEWORKS}"
fi

if [ -d "${IOS_FRAMEWORKS}${FRAMEWORK_NAME}.framework" ]; then
	rm -rf "${IOS_FRAMEWORKS}${FRAMEWORK_NAME}.framework"
fi

cp -R "${UNIVERSAL_OUTPUTFOLDER}/${FRAMEWORK_NAME}.framework" "${IOS_FRAMEWORKS}"

$(/usr/libexec/PlistBuddy "${IOS_PLIST_PATH}" -c "Delete :branch" 2> /dev/null)
$(/usr/libexec/PlistBuddy "${IOS_PLIST_PATH}" -c "Delete :rev" 2> /dev/null)
$(/usr/libexec/PlistBuddy "${IOS_PLIST_PATH}" -c "Delete :built" 2> /dev/null)

# Step 7. Convenience step to open the project's directory in Finder
#open "${PROJECT_DIR}"
