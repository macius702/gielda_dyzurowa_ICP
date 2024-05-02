#! /usr/bin/env bash

# Define dfx command path
DFX_PATH=/home/Matiki/.local/share/dfx/bin/dfx

# The selected code starts the DFINITY development network (dfx) in the background.
# It's set to listen on all network interfaces (0.0.0.0) on port 4943. 
$DFX_PATH start --background --clean --host 0.0.0.0:4943

# Navigate to the 'd' directory, which contains the main project files
cd d

# Install npm dependencies
npm install

# Deploy using dfx. The first pass, which may end with an error, is necessary to generate some .did files.
$DFX_PATH deploy

# Deploy using dfx a second time. This is necessary because the first pass only creates some .did files.
$DFX_PATH deploy

# Open a bash shell
/bin/bash