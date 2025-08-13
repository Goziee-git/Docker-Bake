#!/bin/bash
set -e

echo "Building with Depot..."
echo "====================="

# Check if depot is installed
if ! command -v depot &> /dev/null; then
    echo "Depot CLI not found. Installing..."
    curl -L https://depot.dev/install-cli.sh | sh
fi

# Record start time
start_time=$(date +%s)

# Build with depot (requires depot project setup)
# Replace 'your-project-id' with your actual Depot project ID
depot bake --project=your-project-id

# Calculate build time
end_time=$(date +%s)
build_time=$((end_time - start_time))

echo "Depot build completed in ${build_time} seconds"
echo "Images built:"
docker images | grep myapp
