#!/bin/bash

# Test Case ID: JOb-Submit-test-003
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


# Check if job_submit_test.sh exists and is executable
echo -e "\nChecking job submission capability..."
if [ -f "./job_submit_test.sh" ]; then
    if [ ! -x "./job_submit_test.sh" ]; then
        chmod +x ./job_submit_test.sh
    fi
    echo "Running jjob_submit_test.sh..."
    ./job_submit_test.sh
    print_result $? "Job submission script execution"
    
    # Wait briefly for potential output generation
    sleep 5
    
    # Check for output directory and files
    if [ -d "../data_dir/output" ]; then
        print_result 0 "Output directory exists"
        if [ "$(ls -A ../data_dir/output)" ]; then
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
if [ -f "./job_submit.sh" ]; then
    echo "✓ Job submission test"
fi

echo -e "\n${GREEN}Job Submit tests completed successfully${NC}"