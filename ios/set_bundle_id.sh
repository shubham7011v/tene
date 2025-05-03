#!/bin/bash

# Script to set the appropriate bundle ID based on the ENV flag
# Usage: ./set_bundle_id.sh [dev|prod]

# Default to dev if no argument is provided
ENV=${1:-dev}

# Define bundle IDs
DEV_BUNDLE_ID="com.example.tene"
PROD_BUNDLE_ID="com.teneapp.production"

# Get the path to the project.pbxproj file
PBXPROJ_PATH="Runner.xcodeproj/project.pbxproj"

if [ "$ENV" == "prod" ]; then
  echo "Setting bundle ID to production: $PROD_BUNDLE_ID"
  BUNDLE_ID=$PROD_BUNDLE_ID
else
  echo "Setting bundle ID to development: $DEV_BUNDLE_ID"
  BUNDLE_ID=$DEV_BUNDLE_ID
fi

# Use sed to replace the bundle ID in the project.pbxproj file
sed -i '' "s/PRODUCT_BUNDLE_IDENTIFIER = .*;/PRODUCT_BUNDLE_IDENTIFIER = $BUNDLE_ID;/g" "$PBXPROJ_PATH"

echo "Bundle ID updated successfully" 