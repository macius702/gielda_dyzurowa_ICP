
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

declare -a data
declare -a expected_responses
declare -a endpoints
declare -a commands

# Add your data, expected responses, endpoints, and commands here
data[0]='{ "hello": "world" }'
expected_responses[0]='{"dutySlots":[],"message":"Hello World from GET /duty/slots/json","statusCode":200}'
endpoints[0]="/duty/slots/json"
commands[0]="GET"

data[1]='{
  "username": "D1",
  "password": "a",
  "role":  "Doctor",
  "specialty": 12,
  "localization": "example_localization"
}'
expected_responses[1]='{"key":1,"message":"User registered","statusCode":200}'
endpoints[1]="/auth/register"
commands[1]="POST"

# Loop over the arrays
for i in "${!data[@]}"; do
    echo "Issuing curl command for testing..."
    curl_command="curl -X ${commands[$i]} -H \"Content-Type: application/json\" -d '${data[$i]}' http://$canister_id.localhost:$webserver_port${endpoints[$i]}"
    echo $curl_command
    response=$(eval $curl_command)

    echo "Response from server:"
    echo $response 

    if [ "$response" == "${expected_responses[$i]}" ]; then
        echo "Test passed"
    else
        echo "Test failed"
        echo "Expected response:"
        echo "${expected_responses[$i]}"
        echo "Actual response:"
        echo $response
    fi
done