#!/usr/bin/env bash

file_name=$1

echo "Issuing curl command for testing..."
canister_id=$(jq -r '.canister_id' $file_name)
webserver_port=$(jq -r '.webserver_port' $file_name)
curl_command=("curl" "-X" "GET" "-H" "Content-Type: application/json" "-d" "{ \"hello\": \"world\" }" "http://$canister_id.localhost:$webserver_port/duty/slots/json")
echo "${curl_command[@]}"
response=$("${curl_command[@]}")

echo "Response from server:"

echo $response | jq

expected_response='{"dutySlots":[],"message":"Hello World from GET /duty/slots/json","statusCode":200}'
# expected_response='{
#     "dutySlots": [
#         {
#             "assigned_doctor_id": null,
#             "currency": null,
#             "end_date_time": 0,
#             "hospital_id": 1,
#             "price_from": 234,
#             "price_to": null,
#             "required_specialty": 4,
#             "start_date_time": 355,
#             "status": "Open"
#         },
#         {
#             "assigned_doctor_id": null,
#             "currency": null,
#             "end_date_time": 0,
#             "hospital_id": 1,
#             "price_from": 233,
#             "price_to": null,
#             "required_specialty": 4,
#             "start_date_time": 356,
#             "status": "Waiting"
#         }
#     ],
#     "message": "Hello World from GET /duty/slots/json",
#     "statusCode": 200
# }'

if [ "$response" == "$expected_response" ]; then
    echo "Test passed"
else
    echo "Test failed"
    echo "Expected response:"
    echo $expected_response
    echo "Actual response:"
    echo $response
fi



