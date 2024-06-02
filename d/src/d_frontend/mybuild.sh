#! /usr/bin/env bash

# Build and Run Modes:
# 1. local: Deploys to the local replica. Ideal for development and testing.
# 2. playground: Deploys to the playground (which is on the mainnet). This is a free service but is limited to 20-minute sessions.
# 3. mainnet: Deploys to the mainnet. This is the production environment and consumes cycles.

if [ -z "$1" ]
then
    echo "Please provide the mode as the first parameter"
    exit 1
fi

if [ "$1" == "playground" ]
then
    echo "Deploying to the playground"
    deploy_param="--playground"
elif [ "$1" == "local" ]
then
    echo "Deploying to local"
    deploy_param=""
elif [ "$1" == "mainnet" ]
then
    echo "Deploying to mainnet"
    deploy_param="--network=ic"
else
    echo "Invalid mode. Please provide the mode as the first parameter"
    exit 1
fi

# dfx stop
# dfx start --clean --background
# flutter clean
# flutter pub get

echo "Running canister create with parameter: $deploy_param"
dfx canister create d_backend $deploy_param
dfx canister create d_frontend $deploy_param

echo "Running dart generate_config.dart with parameter: $1"
dart generate_config.dart $1

echo "Running flutter build web --release"
flutter build web --release

echo "Running dfx deploy with parameter: $deploy_param"
dfx deploy -v $deploy_param
flutter devices

# if [ "$1" == "playground" ]
# then
#     source web_front_end.sh
#     xdg-open https://$FRONTEND_CANISTER_ID.ic0.app &
#     flutter run --release -d emulator-5554 &
# elif [ "$1" == "local" ]
# then
#     flutter run --release -d chrome &
#     flutter run --release -d emulator-5554 & # (cd build/web && http-server  -p 8765)
# fi

