Guide Document for bash scripts to carry out tests on Ochestrator and Worker packges. To be able to run the bash scripts, please follow below steps. 

#Setup Ochestrator

Start the Ochestrator fast-api application with a valid .env file. 
    checks DB user name and ports. 

Start the Worker fast-api application, ensure the Ochestrator IP is updated in main.py
    (This needs to be setup with your local IP 172.16.x.x.)
    Repeat this for any worker apis that are spun up, ensure not to clash ports. 


1. Installation-test-001
Script: test001.sh

This test goes through confirming that the Orchestrator application is able to build and can be deployed. This test can also serve to test and confirm that a worker can also be built and started. Defualt script will test for Orchestrator which in current build will run on port 8003. Amend this port to test a different FastAPI endpoint. 

2. Installation-test-002
Script: test002.sh

This test aims to verify that the input and output folders are successfully mounted to the docker container. 

3. Job-Submit-001
Script: test003.sh

This test aims to verify that the job submission works correctly, This test will mainly be used with the worker repositories as they are responsible for producing required output files. Test checks if worker api node is running. and we submit a http POST requst for the worker to process a job. A succesfull test involves output/intrim folder holding data. 

4. Nominal-operations-001
Script: test005.sh

This test is to ensure that the Orchestrator application is working as intended and is able to communicate with a worker node. The test runs through the following checks by making some curl requests to the Orchestrator. 
    ~ curl request to "/" to confirm the Orchestrator is up. 
    ~ curl "POST" request to add a Server/Worker to the worker pool. 
    ~ curl "GET" request to confirm the server has been added. 
    ~ curl "POST" submit job to be processed by added server., confirm we recieve a 200, fail if we get 422. 
    ~ curl "GET" logs from worker, this should result in logs from worker been added the orchestrator.log file. Currently worker logs are stored in Memory. this is to be amended and to also save the logs in a file. 
    ~ a check to confirm the job has been carried out, and it is marked as completed in DB. When a worker has finished processing a job, it sends a POST reqeus     to "POST /worker-report-update/15" if this is a status 200, the job has been updated on the db. If this is any other status code, it has failed. 
    Pass on above confirms the Orchestrator is working as intended. 

5. Nominal-operations-002
Script: test006.sh


6. Error-Handling-001
Script: test004.sh 
 Ensures that various aspects of error handling are captured correctly. This test will cover the case where an incomplete product is present, manifest.xml file or time_in.nc.The code should report the fault successfully in the log files, both in the worker.log file and the job specific log file in the logs folder. This test should first be ran on the worker node individually, and also on via the Orcherstrator. 

7. Error-Handling-002
Script: test007.sh
    Ensures that various aspects of error handling are captured correctly. This test will cover the case where an issue with the manifest file prevents the editing of the attributes.