#! /usr/bin/env bash



# Function to build the Docker image
build_image() {
    docker build -t rust_one_image .
    echo
}

# Function to run the Docker container
run_container() {
    mode=$1
    echo "Running container in $mode mode..."
    if [ "$mode" == "test" ]; then
        echo "Starting container in detached mode..."
        docker run -d -t -p 4943:4943 --name gielda_dyzurowa_ICP -v "$(pwd)":/canister rust_one_image
    else
        echo "Starting container in interactive mode..."
        docker run -it --rm -p 4943:4943 --name gielda_dyzurowa_ICP -v "$(pwd)":/canister rust_one_image
    fi

}

# Function to stop and remove the Docker container
stop_container() {
    docker stop gielda_dyzurowa_ICP && docker rm gielda_dyzurowa_ICP
}


# Check if the first command-line argument is "test"
if [ "$1" == "test" ]; then
    stop_container
    build_image

    run_container test

    docker logs -f gielda_dyzurowa_ICP &

    file_name="./from_backend.json"
    rm -f $file_name

    # Wait until the background container writes "INITIALIZED" into the ./from_backend.json file
    echo "Waiting for the background container to finish..."
    start_time=$(date +%s)
    while ! grep -q "INITIALIZED" $file_name
    do
        sleep 10
        current_time=$(date +%s)
        elapsed_time=$((current_time - start_time))
        echo "Elapsed time: $elapsed_time seconds"
    done
    echo "Background container finished."
    docker ps
    ./test.sh $file_name
    stop_container
else
    stop_container
    build_image
    run_container
fi