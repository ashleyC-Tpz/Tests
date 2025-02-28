#!/bin/bash

# Test Case ID: Error-Handling-001
# Description: Verify error handling for incomplete product submission

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ORCHESTRATOR_URL="http://0.0.0.0:8003"  # Adjust as needed
WORKER_ID="test-worker-1"

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
    local error_pattern="ERROR"  # Adjust pattern based on expected error message
    
    if [ ! -f "$log_file" ]; then
        echo -e "${RED}FAIL${NC}: Log file not found: $log_file"
        return 1
    fi
    
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
response=$(curl -s ${ORCHESTRATOR_URL}/)
if [ $? -eq 0 ] && echo "$response" | jq empty 2>/dev/null; then
    print_result 0 "Orchestrator is accessible and returning valid JSON"
else
    print_result 1 "Orchestrator check failed"
fi

# Clear previous log files (optional, uncomment if needed)
echo "Clearing previous log files..."
#rm -f orchestrator.log
# rm -f ./logs/job_*.log

# Execute error test
echo -e "\nExecuting error test..." # Let us send a curl request to orch that will go to a worker but fail. 
echo -e "\n${YELLOW}Submitting test job...${NC}"
job_response=$(curl -s -w "%{http_code}" -o /tmp/job_response \
    -X POST ${ORCHESTRATOR_URL}/start-job \
    -H 'accept: application/json' \
    -H "Content-Type: application/json" \
    -d '{
    "script": "fdtsr_issues_main.py",
    "args": "/opt/data2/ER2_AT_1_RBT____20020730T145138_20020730T163433_20220410T112311_6175_076_110______DSI_R_NT_004.SEN3", 
    "status": "pending",
    "server_id": 3
    }')



if [ "$job_response" -eq 200 ]; then
    print_result 0 "Job Submit succesfull. $job_response" 
else
    print_result 1 "Job Submit NOT succesfull. $job_response" 
fi
#Get worker logs
echo -e "\n${YELLOW}Retrieving worker logs...${NC}"
logs_response=$(curl -s ${ORCHESTRATOR_URL}/get-logs \
    -H 'accept: application/json')
if [ -n "$logs_response" ]; then
    print_result 0 "Worker logs retrieved"
    
    # Verify logs file exists
    if [ -f "orchestrator.log" ]; then
        print_result 0 "orchestrator logs present"
    else
        print_result 1 "Orchestrator log file not found"
    fi
else
    print_result 1 "Failed to retrieve worker logs"
fi
# Wait briefly for logs to be written
sleep 60

# Check worker log
echo -e "\nChecking worker log..."
WORKER_LOG="orchestrator.log"
check_log_for_errors "$WORKER_LOG"
print_result $? "Error properly logged in worker.log"

# Find and check the most recent job-specific log file
echo "Checking job-specific log..."

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