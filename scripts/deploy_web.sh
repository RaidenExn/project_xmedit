#!/bin/bash

# Build the web application with the correct base-href for GitHub Pages subpath
echo "Building web application for /project_xmedit/demo/ ..."
flutter build web --base-href "/project_xmedit/demo/" --release

echo "Build complete. Files are in build/web/"
