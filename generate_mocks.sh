#!/bin/bash

# Script to generate mock files for tests
echo "Generating mocks for driver excluded zones tests..."

# Run build runner to generate mocks
flutter pub run build_runner build --delete-conflicting-outputs

echo "Mock generation completed!"