#! /usr/bin/env bash

# Build and Run Modes:
# 1. local: Deploys to the local replica. Ideal for development and testing.
# 2. playground: Deploys to the playground (which is on the mainnet). This is a free service but is limited to 20-minute sessions.
# 3. mainnet: Deploys to the mainnet. This is the production environment and consumes cycles.

set -e


mode=${1:-local}

echo "mode=$mode"

if [ -z "$mode" ]
then
    echo "Please provide the mode as the first parameter: local, playground or mainnet"
    exit 1
fi

if [ "$mode" == "playground" ]
then
    echo "Deploying to the playground"
    deploy_param="--playground"
elif [ "$mode" == "local" ]
then
    echo "Deploying to local"
    deploy_param=""
elif [ "$mode" == "mainnet" ]
then
    echo "Deploying to mainnet"
    deploy_param="--network=ic"
    echo "not supported yet"
    exit 1
else
    echo "Invalid mode. Please provide the mode as the first parameter: local, playground or mainnet"
    exit 1
fi

dart format --line-length 120 *.dart integration_test/*.dart lib/*.dart
# dart format dart format --line-length 80 *.dart integration_test/*.dart lib/*.dart

# dfx stop
# dfx start --clean --background &
dfx start --background &
# flutter clean
# flutter pub get

echo "Running canister create with parameter: $deploy_param"
dfx canister create d_backend $deploy_param
dfx canister create d_frontend $deploy_param

echo "Running dart generate_config.dart with parameter: $mode"
dart generate_config.dart $mode

echo "Running build_runner build --delete-conflicting-outputs"
dart run build_runner build --delete-conflicting-outputs    # Build the generated files



echo "Running flutter build web --release"
flutter build web --profile --dart-define=Dart2jsOptimization=O0 --source-maps


echo "Running dfx deploy with parameter: $deploy_param"
dfx deploy -v $deploy_param


flutter devices

if [ "$mode" == "playground" ]
then
    source web_front_end.sh
    xdg-open https://$FRONTEND_CANISTER_ID.ic0.app &
    flutter run --release -d emulator-5554 &
elif [ "$mode" == "local" ]
then
    # (cd build/web && http-server  -p 8765)
    # flutter run -d chrome
    # flutter run --release -d emulator-5554
    flutter run -d emulator-5554
    # (cd build/web && http-server  -p 8765)


    # flutter test integration_test/app_test.dart

fi

