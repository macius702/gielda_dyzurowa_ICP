abstract class Status {
  String getString();

  void handleError() {
    print(getString());
  }
}

class Response extends Status {
  // Response implementation

  @override
  String getString() {
    return 'Response';
  }
}

class GetUserDataResponse extends Response {
  final int id;
  final String role;

  GetUserDataResponse({required this.id, required this.role});

  factory GetUserDataResponse.fromJson(Map<String, dynamic> json) {
    return GetUserDataResponse(
      id: json['_id'],
      role: json['role'],
    );
  }

  @override
  String getString() {
    return 'GetUserDataResponse: id=$id, role=$role';
  }
}

class ExceptionalFailure implements Status {
  @override
  String getString() {
    return 'ExceptionalFailure';
  }

  @override
  void handleError() {
    print('Operation failed with an exceptional failure: ${getString()}');
  }
}

class Error implements Status {
  @override
  String getString() {
    return 'Error';
  }

  @override
  void handleError() {
    print('Operation failed with an error: ${getString()}');
  }
}

enum UserRole {
  doctor,
  hospital,
}
