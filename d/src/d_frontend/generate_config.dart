import 'dart:io';
import 'dart:convert';

void main(List<String> args) async {
  if (args.length != 1) {
    print('You must pass exactly one argument.');
    return;
  }

  String mode = args[0];
  print("Generating config file for $mode mode.");

  if (mode != 'playground' && mode != 'local' && mode != 'network') {
    print('Invalid argument. Must be one of: playground, local, mainnet');
    return;
  }

  var filePath = '../../.dfx/$mode/canister_ids.json';
  var file = File(filePath);

  if (await file.exists()) {
    var content = await file.readAsString();
    var jsonContent = jsonDecode(content);
    var backendCanisterId = jsonContent['d_backend'][mode];
    var frontend_canister_id = jsonContent['d_frontend'][mode];

    //to file web_front_end.sh print https://<frontend_canister_id>.icp0.io/

    var outputFile = File('web_front_end.sh');
    await outputFile.writeAsString('''
export FRONTEND_CANISTER_ID=$frontend_canister_id
    ''');

    outputFile = File('lib/config.dart');
    await outputFile.writeAsString('''
const backendCanisterId = '$backendCanisterId';
enum Mode {    playground,    local,    network  }
Mode mode = Mode.$mode;

    ''');

    print('File generated successfully.');
  } else {
    print('File does not exist.');
  }
}
