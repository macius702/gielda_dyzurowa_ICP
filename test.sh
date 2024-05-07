
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

declare -A curl_commands
declare -A expected_responses


# Add your curl commands and expected responses here
data='{ "hello": "world" }'
command="/duty/slots/json"
expected_responses[0]='{"dutySlots":[],"message":"Hello World from GET /duty/slots/json","statusCode":200}'
curl_commands[0]="curl -X GET -H \"Content-Type: application/json\" -d '$data' http://$canister_id.localhost:$webserver_port$command"

data='{
  "username": "D1",
  "password": "a",
  "role":  "Doctor",
  "specialty": 12,
  "localization": "example_localization"
}'
command="/auth/register"
expected_responses[1]='{"key":1,"message":"User registered","statusCode":200}'
curl_commands[1]="curl -X POST -H \"Content-Type: application/json\" -d '$data' http://$canister_id.localhost:$webserver_port$command"


for i in "${!curl_commands[@]}"; do
    echo "Issuing curl command for testing..."
    echo "${curl_commands[$i]}"
    response=$(eval "${curl_commands[$i]}")

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

