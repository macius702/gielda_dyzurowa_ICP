# gielda_dyzurowa_ICP Project

## Prerequisites

- Git
- Docker

## Instructions

1. **Clone the repository**

    Use the following command to clone the repository:

    ```bash
    git clone git@github.com:macius702/gielda_dyzurowa_ICP.git
    ```

2. **Navigate into the project directory**

    Use the following command to navigate into the cloned repository:

    ```bash
    cd gielda_dyzurowa_ICP
    ```

3. **Build and run the Docker image**

    Use the following command to build the Docker image and run it:

    ```bash
    ./build_and_run.sh
    ```


## Useful commands

For Docker, you can run the following command:

```bash
command="curl -X POST -H \"Content-Type: application/json\" -d \"{ \\\"hello\\\": \\\"world\\\" }\" \"http://$(dfx canister id d_backend).localhost:$(dfx info webserver-port)\"" ; echo $command
```

After running this command in the Docker terminal, you can copy the output and paste it into the host's terminal to execute it.
