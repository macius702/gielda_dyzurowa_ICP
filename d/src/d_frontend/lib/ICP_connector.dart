import 'dart:io';
import 'package:agent_dart/agent_dart.dart';
import 'print.dart';

class ICPconnector {
  /// AgentFactory is a factory method that creates Actor automatically.
  /// Save your strength, just use this template
  AgentFactory? _agentFactory;

  /// CanisterCator is the actor that make all the request to Smartcontract.
  CanisterActor? get actor => _agentFactory?.actor;
  final String canisterId;
  final String url;

  ICPconnector({required this.canisterId, required this.url}) {
    mtlk_print('canisterId: $canisterId');
    mtlk_print('url: $url');
  }
  // A future method because we need debug mode works for local developement
  Future<void> setAgent(
      {String? newCanisterId, ServiceClass? newIdl, String? newUrl, Identity? newIdentity, bool? debug}) async {
    mtlk_print('newCanisterId: $newCanisterId');
    mtlk_print('newIdl: $newIdl');
    mtlk_print('newUrl: $newUrl');
    mtlk_print('newIdentity: $newIdentity');
    mtlk_print('debug: $debug');

    try {
      // Your network request code here

      _agentFactory ??= await AgentFactory.createAgent(
          canisterId: newCanisterId ?? canisterId,
          url: newUrl ?? url,
          idl: newIdl ?? IDL.Service({}),
          identity: newIdentity,
          debug: debug ?? true);

      mtlk_print("After createAgent");
    } catch (e) {
      if (e is SocketException) {
        mtlk_print('Cannot connect to the server. Please check your internet connection and server status.');
        mtlk_print('Exception: $e');
      } else {
        // Re-throw the exception for further handling
        rethrow;
      }
    }
  }
}
