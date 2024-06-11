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

    Use the following command to build the Docker image and run it in interactive mode:

    ```bash
    ./build_and_run.sh
    ```
    You can then go to another terminal and run tests with:
    ```
    ./test.sh from_backend.json
    ```
    This command will run the tests using the data from `from_backend.json`.

4. **Or build, run and test in one go**

    ```
    ./build_and_run.sh test
    ```
    This command will build the Docker image, run it in detached mode, and then run the tests.

## Useful commands

For Docker, you can run the following command:

```bash
command="curl -X POST -H \"Content-Type: application/json\" -d \"{ \\\"hello\\\": \\\"world\\\" }\" \"http://$(dfx canister id d_backend).localhost:$(dfx info webserver-port)\"" ; echo $command
```

After running this command in the Docker terminal, you can copy the output and paste it into the host's terminal to execute it.

# TODO according to: https://docs.flutter.dev/cookbook/design/drawer



- [x] 2 app_tests.dart - > one for register hospital, one for doctor
- [x] Prepare body: widgets (forms - h0ome, register, show users) array 
- [x] Integrate into Drawer
- [x] Extract LoginForm
- [x] use CommonAppBar 
- [x] cookies
- [x] Logout
- [x] Back to one test
- [ ] and test for Login
- [ ] // Handle dismiss

# TODO others


- [ ] is router async - I mean no need to specifically guard the common data operations 
- [ ] @Query("canisterId") canisterId: String into headers
- [ ] into SharedPreferences some data - cookie , what else ?
- [ ] in JWT add nonce

