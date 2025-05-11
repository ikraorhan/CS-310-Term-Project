#!/bin/bash

# Find the flutter_native_timezone plugin build file
PLUGIN_DIR=$(find ~/.pub-cache -name "flutter_native_timezone" -type d | grep android | head -1)
PLUGIN_GRADLE_FILE="$PLUGIN_DIR/build.gradle"

if [ ! -f "$PLUGIN_GRADLE_FILE" ]; then
  echo "Could not find flutter_native_timezone plugin build.gradle file."
  exit 1
fi

echo "Found plugin gradle file at: $PLUGIN_GRADLE_FILE"

# Create a backup
cp "$PLUGIN_GRADLE_FILE" "${PLUGIN_GRADLE_FILE}.bak"

# Modify the Kotlin version
sed -i '' 's/ext.kotlin_version = .*/ext.kotlin_version = "1.8.22"/' "$PLUGIN_GRADLE_FILE"

# Add Java 8 compatibility
if ! grep -q "sourceCompatibility" "$PLUGIN_GRADLE_FILE"; then
  echo "
java {
    sourceCompatibility = JavaVersion.VERSION_1_8
    targetCompatibility = JavaVersion.VERSION_1_8
}
" >> "$PLUGIN_GRADLE_FILE"
fi

echo "Modified plugin build.gradle file to use Kotlin 1.8.22 and Java 8 compatibility." 