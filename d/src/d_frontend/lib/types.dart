abstract class Status {
  String getString();
}

class Response implements Status {
  // Response implementation

  @override
  String getString() {
    // Return a string representation of the Response object
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
    // Return a string representation of the GetUserDataResponse object
    return 'GetUserDataResponse: id=$id, role=$role';
  }
}

class ExceptionalFailure implements Status {
  @override
  String getString() {
    return 'ExceptionalFailure';
  }
}

class Error implements Status {
  @override
  String getString() {
    return 'Error';
  }
}

enum UserRole {
  doctor,
  hospital,
}
