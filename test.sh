
#!/usr/bin/env bash
# Example usage: ./test.sh from_backend.json


GREEN='\033[0;32m'
NC='\033[0m' # No Color



if [ $# -eq 0 ]; then
    echo "Usage: $0 <file>"
    echo "One argument is mandatory, which is the file from backend."
    exit 1
fi

file_name=$1

canister_id=$(jq -r '.canister_id' $file_name)
webserver_port=$(jq -r '.webserver_port' $file_name)

# JSON array of records
json_array='[
    {
        "data": {
            "hello": "world"
        },
        "command": "GET",
        "endpoint": "/duty/slots/json",
        "expected_response": {
            "dutySlots": [],
            "message": "Hello World from GET /duty/slots/json",
            "statusCode": 200
        }
    },
    {
        "data": {
            "username": "D2",
            "password": "a",
            "role": "doctor",
            "specialty": 12,
            "localization": "example_localization"
        },
        "command": "POST",
        "endpoint": "/auth/register",
        "expected_response": "{\"key\":1,\"message\":\"User registered\",\"statusCode\":200}"
    },
    {
        "data": {
            "hello": "world"
        },
        "command": "GET",
        "endpoint": "/users",
        "expected_response": {
            "message": "Hello World from GET /users",
            "statusCode": 200,
            "users": [
                {
                    "email": null,
                    "localization": "example_localization",
                    "password": "2ce11de647a6f556268d4ae9ec33413dbb39e8c66a7c6344854460b790932016",
                    "phone_number": null,
                    "role": "doctor",
                    "specialty": 12,
                    "username": "D2"
                }
            ]
        }
    },
    {
        "data": {
            "username": "D3",
            "password": "b",
            "role": "doctor",
            "specialty": 12,
            "localization": "example_localization"
        },
        "command": "POST",
        "endpoint": "/auth/register",
        "expected_response": {
            "key": 2,
            "message": "User registered",
            "statusCode": 200
        }
    },
    {
        "data": {
            "hello": "world"
        },
        "command": "GET",
        "endpoint": "/users",
        "expected_response": {
            "message": "Hello World from GET /users",
            "statusCode": 200,
            "users": [
                {
                    "email": null,
                    "localization": "example_localization",
                    "password": "2ce11de647a6f556268d4ae9ec33413dbb39e8c66a7c6344854460b790932016",
                    "phone_number": null,
                    "role": "doctor",
                    "specialty": 12,
                    "username": "D2"
                },
                {
                    "email": null,
                    "localization": "example_localization",
                    "password": "d5653d3b9589851de6dd763749c19bb876c53e5924835c31c2ac48abd9e9ec86",
                    "phone_number": null,
                    "role": "doctor",
                    "specialty": 12,
                    "username": "D3"
                }
            ]
        }
    },
    {
        "data": {
            "username": "D2",
            "password": "a"
        },
        "command": "POST",
        "endpoint": "/auth/login",
        "expected_response": {
            "message": "User logged in",
            "statusCode": 200,
            "username": "D2"
        }
    }    
]'

# Save the JSON array to a file
echo $json_array > records.json

# Get the length of the array
length=$(jq '. | length' records.json)

# Loop over the array
total_tests=0
failed_tests=0
failed_tests_indices=()

for (( i=0; i<$length; i++ )); do
    total_tests=$((total_tests+1))
    record=$(jq -c ".[$i]" records.json)
    data=$(echo $record | jq -r '.data')
    expected_response=$(echo $record | jq -r '.expected_response')
    expected_response=$(echo $expected_response | jq -c .)
    endpoint=$(echo $record | jq -r '.endpoint')
    command=$(echo $record | jq -r '.command')

    echo "Issuing curl command for testing..."
    curl_command="curl -X $command -H \"Content-Type: application/json\" -d '$data' http://$canister_id.localhost:$webserver_port$endpoint"
    echo $curl_command
    response=$(eval $curl_command)
    response=$(echo $response | jq -c .)

    echo "Response from server:"
    echo $response 

    if [ "$response" == "$expected_response" ]; then
        echo "Test passed"
    else
        echo "Test failed"
        echo "Expected response:"
        echo "$expected_response" | jq
        echo "Actual response:"
        echo $response | jq
        failed_tests=$((failed_tests+1))
        failed_tests_indices+=($i)
    fi
done

if [ $failed_tests -eq 0 ]; then
    echo -e "${GREEN}All tests passed${NC}"
else
    echo "Total tests: $total_tests"
    echo "Failed tests: $failed_tests"
    echo "Failed tests indices: ${failed_tests_indices[@]}"
fi
# Remove the temporary file
rm records.json