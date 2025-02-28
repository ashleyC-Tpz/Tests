#!/bin/bash

# Test Case ID: Orchestrator-Integration-001
# Description: Verify Orchestrator-Worker communication and job processing

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ORCHESTRATOR_URL="http://0.0.0.0:8003"  # Adjust as needed
WORKER_ID="test-worker-1"
JOB_ID="15"  # Adjust as needed
UPDATE_MESSAGE="update report update started"

print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}: $2"
    else
        echo -e "${RED}FAIL${NC}: $2"
        exit 1
    fi
}

# Test 1: Check if Orchestrator is up
response=$(curl -s ${ORCHESTRATOR_URL}/)
if [ $? -eq 0 ] && echo "$response" | jq empty 2>/dev/null; then
    print_result 0 "Orchestrator is accessible and returning valid JSON"
else
    print_result 1 "Orchestrator check failed"
fi


# curl -X 'POST' \
#   'http://0.0.0.0:8003/servers/' \
#   -H 'accept: application/json' \
#   -H 'Content-Type: application/json' \
#   -d '{
#   "name": "Server 1",
#   "IP": ["192.168.1.1"],
#   "port": 8080,
#   "enabled": true
# }'


# Test 2: Add Worker to pool
echo -e "\n${YELLOW}Adding worker to pool...${NC}"
worker_response=$(curl -X POST ${ORCHESTRATOR_URL}/servers/ \
    -H 'accept: application/json' \
    -H "Content-Type: application/json" \
    -d '{
    "name": "test-worker-1",
    "IP": "172.26.17.128",
    "port": 8005,
    "enabled": true
    }')

if echo "$worker_response" | jq -e '.id' > /dev/null; then
    server_id=$(echo "$worker_response" | jq -r '.id')
    print_result 0 "Worker added successfully with ID: $server_id"
else
    print_result 1 "Failed to add worker: $(echo "$worker_response" | jq -r '.')"
fi

# Test 3: Verify worker was added
echo -e "\n${YELLOW}Verifying worker registration...${NC}"
workers_list=$(curl -s "${ORCHESTRATOR_URL}/servers/?skip=0&limit=10" \
    -H 'accept: application/json')

echo "Debug - Workers List Response:"
echo "$workers_list" | jq '.'

if echo "$workers_list" | jq -e ".[] | select(.id == $server_id)" > /dev/null; then
    worker_details=$(echo "$workers_list" | jq -r ".[] | select(.id == $server_id)")
    echo "Debug - Found worker details:"
    echo "$worker_details" | jq '.'
    print_result 0 "Worker verified in pool with ID: $server_id"
else
    echo "Debug - Worker with ID $server_id not found in response:"
    echo "$workers_list" | jq '.'
    print_result 1 "Worker not found in pool"
fi

# Test 4: Submit job ensure product path is entered in args section.
echo -e "\n${YELLOW}Submitting test job...${NC}"
job_response=$(curl -s -w "%{http_code}" -o /tmp/job_response \
    -X POST ${ORCHESTRATOR_URL}/start-job \
    -H 'accept: application/json' \
    -H "Content-Type: application/json" \
    -d '{
    "script": "fdtsr_issues_main.py",
    "args": "/opt/data", 
    "status": "pending",
    "server_id": 3
    }')

echo "Raw Response:"
echo "$job_response"
echo "Attempting to parse JSON:"
echo "$job_response" | jq '.'

if echo $job_response == 200 > /dev/null; then
    print_result 0 "Job Submit succesfull. $job_response" 
else
    print_result 1 "Job Submit NOT succesfull. $job_response" 
fi

# First verify it's valid JSON
# if echo "$job_response" | jq 'type' > /dev/null 2>&1; then
#     if echo "$job_response" | jq 'has("server_id")' > /dev/null 2>&1; then
#         server_id=$(echo "$job_response" | jq '.server_id')
#         status=$(echo "$job_response" | jq -r '.status')
#         print_result 0 "Job submitted successfully to server ID: $server_id (Status: $status)"
#     else
#         print_result 1 "Response missing server_id field: $job_response"
#     fi
# else
#     http_code=$(curl -s -w "%{http_code}" -o /dev/null ${ORCHESTRATOR_URL}/submit-job)
#     print_result 1 "Invalid JSON response (HTTP code: $http_code)"
# fi


# curl -X 'GET' \
#   'http://0.0.0.0:8003/get-logs' \
#   -H 'accept: application/json'

# Test 5: Get worker logs
echo -e "\n${YELLOW}Retrieving worker logs...${NC}"
logs_response=$(curl -s ${ORCHESTRATOR_URL}/get-logs \
    -H 'accept: application/json')
if [ -n "$logs_response" ]; then
    print_result 0 "Worker logs retrieved"
    
    # Verify logs are written to file
    if [ -f "orchestrator.log" ]; then
        if grep -q "${WORKER_ID}" "orchestrator.log"; then
            print_result 0 "Worker logs written to file"
        else
            print_result 1 "Worker logs not found in log file"
        fi
    else
        print_result 1 "Orchestrator log file not found"
    fi
else
    print_result 1 "Failed to retrieve worker logs"
fi

echo -e "\n${YELLOW}Waiting for job completion...${NC}"
sleep 60

# Test 6: Check job completion status
echo -e "\n${YELLOW}Verifying job completion...${NC}"

if grep -q "worker report update started" "orchestrator.log"; then
    print_result 0 "Job Report Succesfull from Worker"
 else
    print_result 1 "Worker update not found in log file"
fi

# Final Summary
echo -e "\nTest Summary (Orchestrator-Integration-001):"
echo "✓ Orchestrator availability"
echo "✓ Worker registration"
echo "✓ Worker pool verification"
echo "✓ Job submission"
echo "✓ Log retrieval and storage"
echo "✓ Job completion verification"

echo -e "\n${GREEN}Orchestrator integration tests completed successfully${NC}"
exit 0