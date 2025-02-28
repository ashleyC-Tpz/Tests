# Guide Document for Test Scripts

This guide covers bash scripts for testing Orchestrator and Worker packages. Follow these steps to run the bash scripts.

## Setup Instructions

### Orchestrator Setup
1. Start the Orchestrator fast-api application with a valid `.env` file
   - Check database username and ports
   - Ensure correct port assignement in `Dockerfile`

### Worker Setup
1. Start the Worker fast-api application
   - Ensure the Orchestrator IP is updated in `main.py` (Use your local IP: 172.16.x.x)
   - When spinning up multiple worker APIs, use different ports to avoid conflicts

## Available Tests

### 1. Installation-test-001
**Script**: `test001.sh`

Confirms that the Orchestrator application can build and deploy. This test can also verify that a worker can be built and started. The default script tests the Orchestrator, which runs on port 8003. Modify this port to test different FastAPI endpoints.

### 2. Installation-test-002
**Script**: `test002.sh`

Verifies that input and output folders are successfully mounted to the docker container.

### 3. Job-Submit-001
**Script**: `test003.sh`

Verifies that job submission works correctly. This test is primarily used with worker repositories as they produce the required output files. The test checks if the worker API node is running and submits an HTTP POST request for the worker to process a job. A successful test will result in data in the output/interim folder.

### 4. Nominal-operations-001
**Script**: `test005.sh`

Ensures the Orchestrator application works as intended and can communicate with a worker node. The test performs these checks:
- curl request to `/` to confirm the Orchestrator is running
- curl `POST` request to add a Server/Worker to the worker pool
- curl `GET` request to confirm the server has been added
- curl `POST` to submit a job for processing by the added server (confirm 200 response, fail on 422)
- curl `GET` logs from worker (logs should be added to the orchestrator.log file)
- Check to confirm the job has been completed and marked as completed in the database

When a worker finishes processing a job, it sends a POST request to `/worker-report-update/15`. A 200 status indicates the job was updated in the database; any other status code indicates failure. Passing all these checks confirms the Orchestrator is working as intended.

### 5. Nominal-operations-002
**Script**: `test006.sh`

This test is to ensure that the application is working as intended and is producing products as expected but with 10 requests submitted being able to be processed.

### 6. Error-Handling-001
**Script**: `test004.sh`

Ensures various aspects of error handling are captured correctly. This test covers cases where an incomplete product is present (missing manifest.xml file or time_in.nc). The code should report the fault in both the worker.log file and the job-specific log file in the logs folder. This test should be run first on the worker node individually and then via the Orchestrator.

### 7. Error-Handling-002
**Script**: `test007.sh`

Ensures various aspects of error handling are captured correctly. This test covers cases where an issue with the manifest file prevents the editing of attributes.