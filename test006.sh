#!/bin/bash

# Test Case ID: Nominal-operations-002
# Description: Verify processing of multiple job submissions (10 requests)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

NUM_JOBS=10
SUCCESS_COUNT=0
FAILED_COUNT=0

print_result() {
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}PASS${NC}: $2"
    else
        echo -e "${RED}FAIL${NC}: $2"
        exit 1
    fi
}

# Check if job_submit_multi.sh exists
if [ ! -f "./batch_orch_test.sh" ]; then
    echo -e "${RED}ERROR${NC}: job_submit_multi.sh not found"
    exit 1
fi

# Make the script executable
chmod +x ./batch_orch_test.sh

# Check if outputs and logs directories exist
for dir in "./outputs/interim" "./logs"; do
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
        echo "Created directory: $dir"
    fi
done

# Count existing files/logs before test
initial_outputs=$(find ./outputs/interim -type f | wc -l)
initial_logs=$(find ./logs -name "*.log" | wc -l)

echo -e "${YELLOW}Starting Multiple Job Submission Test (ID: Nominal-operations-002)${NC}"
echo "Will submit and monitor $NUM_JOBS jobs"

# Execute job submission script
echo -e "\n${YELLOW}Executing batch_orch_test.sh...${NC}"
./batch_orch_test.sh
SUBMIT_EXIT_CODE=$?

if [ $SUBMIT_EXIT_CODE -ne 0 ]; then
    print_result 1 "Job submission script failed with exit code $SUBMIT_EXIT_CODE"
fi

# Wait for processing to complete (adjust timeout as needed to allow for processing)
echo -e "\n${YELLOW}Waiting for all jobs to complete processing...${NC}"
timeout=300  # 5 minutes timeout
elapsed=0
sleep_interval=10

while [ $elapsed -lt $timeout ]; do
    # Count new output files and logs
    current_outputs=$(find ./outputs/interim -type f | wc -l)
    current_logs=$(find ./logs -name "*.log" | wc -l)
    
    new_outputs=$((current_outputs - initial_outputs))
    new_logs=$((current_logs - initial_logs))
    
    echo "Progress: $new_outputs/$NUM_JOBS output files, $new_logs new log files"
    
    # If we've got at least NUM_JOBS new outputs and logs, we're done
    if [ $new_outputs -ge $NUM_JOBS ] && [ $new_logs -ge $NUM_JOBS ]; then
        break
    fi
    
    sleep $sleep_interval
    elapsed=$((elapsed + sleep_interval))
done

if [ $elapsed -ge $timeout ]; then
    print_result 1 "Timeout waiting for jobs to complete"
fi

# Get list of newly created output directories
echo -e "\n${YELLOW}Verifying output files...${NC}"
output_files=$(find ./outputs/interim -type f -newer "$(date -r ./job_submit_multi.sh +%Y%m%d%H%M.%S)")
log_files=$(find ./logs -name "*.log" -newer "$(date -r ./job_submit_multi.sh +%Y%m%d%H%M.%S)")

# Verify each output and log file follows naming convention
echo "Checking naming convention for output files..."
for file in $output_files; do
    filename=$(basename "$file")
    # Check if filename matches pattern: <processing_time>_<product_sensing_start>_<product_sensing_stop>_worker<...>
    if [[ $filename =~ ^[0-9]+_[0-9]+_[0-9]+_worker ]]; then
        ((SUCCESS_COUNT++))
    else
        echo -e "${RED}Invalid output filename format:${NC} $filename"
        ((FAILED_COUNT++))
    fi
done

# Check worker.log for errors
echo -e "\n${YELLOW}Checking worker.log for errors...${NC}"
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

# Verify log files have "script complete" at the end
echo -e "\n${YELLOW}Checking for 'script complete' in log files...${NC}"
complete_count=0
for logfile in $log_files; do
    if grep -q "script complete" "$logfile"; then
        ((complete_count++))
    else
        echo -e "${YELLOW}WARNING:${NC} 'script complete' not found in $logfile"
    fi
done

# Final summary
echo -e "\n${YELLOW}Test Summary:${NC}"
echo "- Expected jobs: $NUM_JOBS"
echo "- Valid output files: $SUCCESS_COUNT"
echo "- Invalid output files: $FAILED_COUNT"
echo "- Log files with 'script complete': $complete_count"

if [ $SUCCESS_COUNT -eq $NUM_JOBS ] && [ $complete_count -eq $NUM_JOBS ]; then
    echo -e "\n${GREEN}PASS:${NC} All $NUM_JOBS jobs completed successfully"
    exit 0
else
    echo -e "\n${RED}FAIL:${NC} Not all jobs completed successfully"
    exit 1
fi