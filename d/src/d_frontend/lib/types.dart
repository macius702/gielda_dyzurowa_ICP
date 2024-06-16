import 'package:decimal/decimal.dart';

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

// for publish duty slot only because register uses only id as string
class Specialty {
  final String id;
  final String name;

  Specialty({required this.id, required this.name});
  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'name': name,
    };
  }

  
  @override
  String  toString() {
    return 'Specialty: id=$id, name=$name';
  }

}

class Hospital {
  final String id;
  final String username;
  final String password;
  final String role;
  final bool profileVisible;

  Hospital({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.profileVisible,
  });

  factory Hospital.fromJson(Map<String, dynamic> json) {
    return Hospital(
      id: json['_id'],
      username: json['username'],
      password: json['password'],
      role: json['role'],
      profileVisible: json['profileVisible'],
    );
  }

  @override
  String toString() {
    return 'Hospital: id=$id, username=$username, password=$password, role=$role, profileVisible=$profileVisible';
  }
  
}

class DutySlotForDisplay {
  final String id;
  final Hospital hospitalId;
  final Specialty requiredSpecialty;
  final String status;
  final String? assignedDoctorId;
  final String startDateTime;
  final String endDateTime;
  final Decimal priceFrom;
  final Decimal priceTo;
  final String currency;

  DutySlotForDisplay({
    required this.id,
    required this.hospitalId,
    required this.requiredSpecialty,
    required this.status,
    required this.assignedDoctorId,
    required this.startDateTime,
    required this.endDateTime,
    required this.priceFrom,
    required this.priceTo,
    required this.currency,
  });

  factory DutySlotForDisplay.fromJson(Map<String, dynamic> json) {
    return DutySlotForDisplay(
      id: json['_id'],
      hospitalId: Hospital.fromJson(json['hospitalId']),
      requiredSpecialty: Specialty(
        id: json['requiredSpecialty']['_id'],
        name: json['requiredSpecialty']['name'],
      ),
      status: json['status'],
      assignedDoctorId: json['assignedDoctorId'],
      startDateTime: json['startDateTime'],
      endDateTime: json['endDateTime'],
      priceFrom: Decimal.parse(json['priceFrom'].toString()),
      priceTo: Decimal.parse(json['priceTo'].toString()),
      currency: json['currency'],
    );
  }

  @override
  String toString() {
    return 'DutySlotForDisplay: id=$id, hospitalId=$hospitalId, requiredSpecialty=$requiredSpecialty, status=$status, assignedDoctorId=$assignedDoctorId, startDateTime=$startDateTime, endDateTime=$endDateTime, priceFrom=$priceFrom, priceTo=$priceTo, currency=$currency';
  }
}
