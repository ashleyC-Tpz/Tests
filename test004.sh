#!/bin/bash

# Test Case ID: Error-Handling-001
# Description: Verify error handling for incomplete product submission

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

# Function to check log file for error messages
check_log_for_errors() {
    local log_file=$1
    local error_pattern="missing input products"  # Adjust pattern based on expected error message
    
    if [ ! -f "$log_file" ]; then
        echo -e "${RED}FAIL${NC}: Log file not found: $log_file"
        return 1
    
    
    if grep -i "$error_pattern" "$log_file" > /dev/null; then
        return 0
    else
        echo -e "${RED}FAIL${NC}: Expected error message not found in $log_file"
        return 1
    fi
}

echo -e "${YELLOW}Starting Error Handling Test (ID: Error-Handling-001)${NC}"

# Check preconditions
echo "Checking preconditions..."

# Verify FastAPI is running
curl -s -f http://0.0.0.0:8005/docs > /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}FAILED${NC}: FastAPI URL is not accessible. Please ensure the application is running."
    exit 1
fi
print_result 0 "Application is running"

# Check if error test script exists
if [ ! -f "./job_submit_error_1.sh" ]; then
    echo -e "${RED}FAILED${NC}: job_submit_error_1.sh not found"
    exit 1
fi
print_result 0 "Error test script found"

# Make error test script executable if it isn't already
chmod +x ./job_submit_error_1.sh

# Clear previous log files (optional, uncomment if needed)
# echo "Clearing previous log files..."
# rm -f ./logs/worker.log
# rm -f ./logs/job_*.log

# Execute error test
echo -e "\nExecuting error test..."
./job_submit_error_1.sh
SUBMIT_EXIT_CODE=$?

# Wait briefly for logs to be written
sleep 2

# Check worker log
echo -e "\nChecking worker log..."
WORKER_LOG="./logs/worker.log"
check_log_for_errors "$WORKER_LOG"
print_result $? "Error properly logged in worker.log"

# Find and check the most recent job-specific log file
echo "Checking job-specific log..."
LATEST_JOB_LOG=$(ls -t ./logs/job_*.log 2>/dev/null | head -n1)
if [ -n "$LATEST_JOB_LOG" ]; then
    check_log_for_errors "$LATEST_JOB_LOG"
    print_result $? "Error properly logged in job-specific log"
    
    # Display relevant error messages (for verification)
    echo -e "\nRelevant error messages from logs:"
    echo "From worker.log:"
    grep -i "error\|fail\|missing" "$WORKER_LOG" | tail -n 3
    
    echo -e "\nFrom job-specific log:"
    grep -i "error\|fail\|missing" "$LATEST_JOB_LOG" | tail -n 3
else
    echo -e "${RED}FAILED${NC}: No job-specific log file found"
    exit 1
fi

# Check that no output was generated (since this should be an error case)
if [ -d "./outputs/interim" ] && [ "$(ls -A ./outputs/interim)" ]; then
    echo -e "${YELLOW}WARNING${NC}: Output files were generated despite error condition"
fi

# Print final test summary
echo -e "\nTest Summary (Error-Handling-001):"
echo "✓ Application accessibility check"
echo "✓ Error test script execution"
echo "✓ Worker log error verification"
echo "✓ Job-specific log error verification"

echo -e "\n${GREEN}Error handling test completed successfully${NC}"
exit 0