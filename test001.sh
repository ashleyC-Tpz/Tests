#!/bin/bash

# Installation Test Case ID: Installation-test-001
# Description: Verify successful application installation and accessibility
# Run the script in same location where Dockerfile is stored or amend step to navigate to install folder. (Line 55)

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

echo -e "${YELLOW}Starting Installation Test (ID: Installation-test-001)${NC}"

# Check preconditions
echo "Checking preconditions..."

# Verify OS
if [[ "$(uname)" != "Linux" ]]; then
    echo -e "${RED}ERROR${NC}: This script must be run on Linux"
    exit 1
fi
print_result $? "Operating system check"

# Check if Docker is installed
check_command docker
print_result $? "Docker installation check"

# Check if Docker Compose is installed
check_command docker compose
print_result $? "Docker Compose installation check"

# Execute installation steps
echo -e "\nExecuting installation steps..."

# Navigate to installation directory (uncomment and modify if needed)
# cd /path/to/installation/directory

# Build Docker containers with no cache
echo "Building Docker containers..."
docker compose build --no-cache
print_result $? "Docker compose build"

# Start Docker containers
echo "Starting Docker containers..."
docker compose up -d
print_result $? "Docker compose up"

# Wait for application to start (adjust sleep time if needed)
echo "Waiting for application to start..."
sleep 10

# Test API accessibility
echo "Testing API accessibility..."
curl -s -f http://0.0.0.0:8005/docs > /dev/null
API_STATUS=$?

if [ $API_STATUS -eq 0 ]; then
    echo -e "${GREEN}SUCCESS${NC}: FastAPI application is accessible at http://0.0.0.0:8005"
else
    echo -e "${RED}FAILURE${NC}: FastAPI application is not accessible"
    
    # Print Docker logs for troubleshooting
    echo -e "\nDocker logs for troubleshooting:"
    docker compose logs
    
    # Clean up
    docker compose down
    exit 1
fi

# Print final test results
echo -e "\nTest Results:"
echo "Test Case ID: Installation-test-001"
echo "Objective: Verify successful application installation"
if [ $API_STATUS -eq 0 ]; then
    echo -e "Status: ${GREEN}PASSED${NC}"
else
    echo -e "Status: ${RED}FAILED${NC}"
fi

# Optional: Clean up (uncomment if needed)
echo -e "\nCleaning up..."
docker compose down
echo -e "\nClean up completed successfully. 

exit $API_STATUS