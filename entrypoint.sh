#! /usr/bin/env bash

# Define dfx command path
DFX_PATH=/home/Matiki/.local/share/dfx/bin/dfx

# The selected code starts the DFINITY development network (dfx) in the background.
# It's set to listen on all network interfaces (0.0.0.0) on port 4943. 
$DFX_PATH start --background --clean --host 0.0.0.0:4943

# Navigate to the 'd' directory, which contains the main project files
cd d
file_name="../from_backend.json"

# Install npm dependencies
npm install

# Deploy using dfx. The first pass, which may end with an error, is necessary to generate some .did files.
$DFX_PATH deploy

# Deploy using dfx a second time. This is necessary because the first pass only creates some .did files.
$DFX_PATH deploy


# the file_name has a json structure
# with fields:
# status: INITIALIZED
# canister_id: <canister_id> which is initialized with command: dfx canister id d_backend
# webserver_port: # - initialized with command: dfx info webserver-port

echo "{\"status\": \"INITIALIZED\", \"canister_id\": \"$($DFX_PATH canister id d_backend)\", \"webserver_port\": $($DFX_PATH info webserver-port)}" > $file_name


# Open a bash shell
/bin/bash