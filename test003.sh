#!/bin/bash

# Test Case ID: Job-Submit-test-003
# Description: Aims to verify that the job submission works correctly

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

echo -e "${YELLOW}Starting Job Submit Test (ID: Job-Submit-test-003)${NC}"

# Check precondition: FastAPI accessibility
echo "Checking preconditions..."
echo "Testing FastAPI URL accessibility..."

curl -s -f http://0.0.0.0:8005/docs > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}FAILED${NC}: FastAPI URL is not accessible. Please ensure the application is running."
    exit 1
fi
print_result 0 "FastAPI URL is accessible"

# Check for Python3 installation
check_command python3
print_result $? "Python3 is installed"

# Execute request_test.py and capture its output
echo -e "\nExecuting job submission test..."
if [ -f "./requests_test.py" ]; then
    echo "Running requests_test.py..."
    
    # Capture the output and error separately
    RESPONSE=$(python3 requests_test.py 2>/tmp/request_error)
    TEST_EXIT_CODE=$?
    
    # Check if the script executed successfully
    if [ $TEST_EXIT_CODE -ne 0 ]; then
        echo -e "${RED}FAILED${NC}: Python script execution failed"
        cat /tmp/request_error
        exit 1
    fi
    
    # Check if response contains expected message
    if echo "$RESPONSE" | grep -q "{'message': 'Job submitted'}"; then
        print_result 0 "Received expected job submission response"
    else
        echo -e "${RED}FAILED${NC}: Unexpected response format"
        echo "Received: $RESPONSE"
        echo "Expected response containing: {'message': 'Job submitted'}"
        exit 1
    fi
    
    # Wait for output generation
    echo "Waiting for job processing..."
    sleep 2
    
    # Check for output directory and files
    if [ -d "./outputs" ]; then
        print_result 0 "Output directory exists"
        if [ -d "./outputs/interim" ] && [ "$(ls -A ./outputs/interim)" ]; then
            print_result 0 "Output files were generated"
        else
            echo -e "${RED}FAILED${NC}: No results found in outputs/interim directory"
            exit 1
        fi
    else
        echo -e "${RED}FAILED${NC}: Output directory was not created"
        exit 1
    fi
else
    echo -e "${RED}FAILED${NC}: requests_test.py not found"
    exit 1
fi

# Print final test summary
echo -e "\nTest Summary (Job-Submit-test-003):"
echo "✓ FastAPI URL accessibility check"
echo "✓ Python3 availability check"
echo "✓ Request test script execution"
echo "✓ Job submission response verification"
echo "✓ Output generation verification"

echo -e "\n${GREEN}Job Submit tests completed successfully${NC}"
exit 0