
#!/usr/bin/env bash
# Example usage: ./test.sh from_backend.json

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
        "data": { "hello": "world" },
        "expected_response": {"dutySlots":[],"message":"Hello World from GET /duty/slots/json","statusCode":200},
        "endpoint": "/duty/slots/json",
        "command": "GET"
    },
    {
        "data": { "username": "D1", "password": "a", "role":  "Doctor", "specialty": 12, "localization": "example_localization" },
        "expected_response": "{\"key\":1,\"message\":\"User registered\",\"statusCode\":200}",
        "endpoint": "/auth/register",
        "command": "POST"
    }
]'

# Save the JSON array to a file
echo $json_array > records.json

# Get the length of the array
length=$(jq '. | length' records.json)

# Loop over the array
for (( i=0; i<$length; i++ )); do
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
        echo "$expected_response"
        echo "Actual response:"
        echo $response
    fi
done

# Remove the temporary file
rm records.json