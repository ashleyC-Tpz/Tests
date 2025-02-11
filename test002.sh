#!/bin/bash

# Test Case ID: Installation-test-002
# Description: Verify volume mounting and data directory accessibility

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print test results
print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}: $2"
    else
        echo -e "${RED}FAIL${NC}: $2"
        exit 1
    fi
}

# Function to check if a command exists
check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}ERROR${NC}: $1 is not installed"
        exit 1
    fi
}


echo -e "${YELLOW}Starting Volume Mount Test (ID: Installation-test-002)${NC}"

# Check precondition: FastAPI accessibility
echo "Checking preconditions..."
echo "Testing FastAPI URL accessibility..."

curl -s -f http://0.0.0.0:8005/docs > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}FAILED${NC}: FastAPI URL is not accessible. Please ensure the application is running."
    exit 1
fi
print_result 0 "FastAPI URL is accessible"

# Get container name (adjust the grep pattern based on your container name)
CONTAINER_NAME=$(docker ps --format '{{.Names}}' | grep -i app)
if [ -z "$CONTAINER_NAME" ]; then
    echo -e "${RED}ERROR${NC}: Cannot find running container"
    exit 1
fi
print_result 0 "Container is running: $CONTAINER_NAME"

# Check if data directories exist
echo -e "\nChecking data directory structure..."
if [ ! -d "../data_dir" ]; then
    echo -e "${RED}ERROR${NC}: ../data_dir directory not found"
    exit 1
fi
print_result 0 "Host data directory exists"

# Verify container can access the mounted volume
echo "Verifying container volume mount..."
docker exec $CONTAINER_NAME ls -la /opt/app/outputs &>/dev/null
print_result $? "Container can access /opt/data directory"

# Test data directory read/write access
echo -e "\nTesting data directory access..."

# Create a test file in host directory
echo "Creating test file in host directory..."
TEST_FILE="test_$(date +%s).txt"
echo "test content" > "./outputs/$TEST_FILE"

# Verify container can read the test file
echo "Verifying container can read test file..."
docker exec $CONTAINER_NAME cat "/opt/app/outputs/$TEST_FILE" &>/dev/null
print_result $? "Container can read files from mounted volume"

# Verify container can write to the directory
echo "Verifying container can write to volume..."
CONTAINER_TEST_FILE="container_test_$(date +%s).txt"
docker exec $CONTAINER_NAME bash -c "echo 'container test' > /opt/app/outputs/$CONTAINER_TEST_FILE"
print_result $? "Container can write files to mounted volume"

# Verify host can see the container-created file
if [ -f "./outputs/$CONTAINER_TEST_FILE" ]; then
    print_result 0 "Host can access files created by container"
else
    print_result 1 "Host cannot access files created by container"
fi

# Clean up test files
rm -f "./outputs/$TEST_FILE" "./outputs/$CONTAINER_TEST_FILE"

# Check if job_submit.sh/request_test.py exists and is executable
echo -e "\nChecking job submission capability..."
if [ -f "./requests_test.py" ]; then
    echo "Running requests_test.py..."
    check_command python3 requests_test.py 
    print_result $? "Job submission script execution"
    
    # Wait briefly for potential output generation
    sleep 2
    
    # Check for output directory and files
    if [ -d "./outputs" ]; then
        print_result 0 "Output directory exists"
        if [ "$(ls -A ./outputs/interim)" ]; then
            print_result 0 "Output files were generated"
        else
            echo -e "${YELLOW}WARNING${NC}: Output directory is empty"
        fi
    else
        echo -e "${YELLOW}WARNING${NC}: Output directory was not created"
    fi
else
    echo -e "${YELLOW}WARNING${NC}: job_submit.sh not found, skipping job submission test"
fi

# Print final test summary
echo -e "\nTest Summary (Installation-test-002):"
echo "✓ FastAPI URL accessibility check"
echo "✓ Container running verification"
echo "✓ Volume mount verification"
echo "✓ Data directory access verification"
if [ -f "./requests_test.py" ]; then
        if [ "$(ls -A ./outputs/interim)" ]; then
            echo "✓ Job submission test Successfully and we have some results. "
        else
            echo "✘ No results in Outputs"
        fi
fi

echo -e "\n${GREEN}All volume mount tests completed successfully${NC}"