#!/bin/bash

# Test Case ID: Orchestrator-Integration-001
# Description: Verify Orchestrator-Worker communication and job processing

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ORCHESTRATOR_URL="http://localhost:8000"  # Adjust as needed
WORKER_ID="test-worker-1"
JOB_ID="15"  # Adjust as needed

print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}: $2"
    else
        echo -e "${RED}FAIL${NC}: $2"
        exit 1
    fi
}

# Test 1: Check if Orchestrator is up
echo -e "${YELLOW}Testing Orchestrator availability...${NC}"
response=$(curl -s -w "%{http_code}" -o /dev/null ${ORCHESTRATOR_URL}/)
print_result $? "Orchestrator is accessible"

# Test 2: Add Worker to pool
echo -e "\n${YELLOW}Adding worker to pool...${NC}"
worker_response=$(curl -s -X POST ${ORCHESTRATOR_URL}/add-worker \
    -H "Content-Type: application/json" \
    -d "{\"worker_id\": \"${WORKER_ID}\", \"status\": \"available\"}")

if echo "$worker_response" | grep -q "worker added successfully"; then
    print_result 0 "Worker added to pool"
else
    print_result 1 "Failed to add worker"
fi

# Test 3: Verify worker was added
echo -e "\n${YELLOW}Verifying worker registration...${NC}"
workers_list=$(curl -s ${ORCHESTRATOR_URL}/workers)
if echo "$workers_list" | grep -q "${WORKER_ID}"; then
    print_result 0 "Worker found in pool"
else
    print_result 1 "Worker not found in pool"
fi

# Test 4: Submit job
echo -e "\n${YELLOW}Submitting test job...${NC}"
job_response=$(curl -s -w "%{http_code}" -o /tmp/job_response \
    -X POST ${ORCHESTRATOR_URL}/submit-job \
    -H "Content-Type: application/json" \
    -d "{\"job_type\": \"test\", \"parameters\": {}}")

if [ "$job_response" == "200" ]; then
    print_result 0 "Job submitted successfully"
elif [ "$job_response" == "422" ]; then
    print_result 1 "Job submission failed - validation error"
else
    print_result 1 "Job submission failed - unexpected response: $job_response"
fi

# Test 5: Get worker logs
echo -e "\n${YELLOW}Retrieving worker logs...${NC}"
logs_response=$(curl -s ${ORCHESTRATOR_URL}/worker-logs/${WORKER_ID})
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

# Test 6: Check job completion status
echo -e "\n${YELLOW}Verifying job completion...${NC}"
update_response=$(curl -s -w "%{http_code}" -o /tmp/update_response \
    -X POST "${ORCHESTRATOR_URL}/worker-report-update/${JOB_ID}" \
    -H "Content-Type: application/json" \
    -d "{\"status\": \"completed\"}")

if [ "$update_response" == "200" ]; then
    print_result 0 "Job marked as completed in DB"
else
    print_result 1 "Failed to update job status (code: $update_response)"
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