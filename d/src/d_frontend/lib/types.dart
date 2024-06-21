import 'package:decimal/decimal.dart';

abstract class Status {
  bool is_success() {
    return true;
  }

  String getString();
  String getMessage() {
    return getString();
  }

  void handleError() {
    print(getString());
  }
}

class Response extends Status {
  // Response implementation
  String message;

  // Response constructor with optional positional argument : message
  Response([this.message = 'Response']);

  @override
  String getString() {
    return message;
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
    return '{ "id": "$id", "role": "$role"}';
  }
}

class ExceptionalFailure extends Status {
  @override
  bool is_success() {
    return false;
  }

  String message;

  // Response constructor with optional positional argument : message
  ExceptionalFailure([this.message = 'ExceptionalFailure']);

  @override
  String getString() {
    return message;
  }

  @override
  void handleError() {
    print('Operation failed with an exceptional failure: ${getString()}');
  }
}

class Error extends Status {
  @override
  bool is_success() {
    return false;
  }

  String message;

  Error([this.message = 'Error']);

  @override
  String getString() {
    return message;
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
  String toString() {
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

class Doctor {
  final String id;
  final String username;
  final String
      password; // TODO: Note: Handling passwords like this is insecure, especially on client-side.
  final String role;
  final String specialty;
  final String localization;
  final bool profileVisible;

  Doctor({
    required this.id,
    required this.username,
    required this.password,
    required this.role,
    required this.specialty,
    required this.localization,
    required this.profileVisible,
  });

  static Doctor? fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return null;
    }

    return Doctor(
      id: json['_id'],
      username: json['username'],
      password: json['password'],
      role: json['role'],
      specialty: json['specialty'],
      localization: json['localization'],
      profileVisible: json['profileVisible'],
    );
  }
}

enum DutyStatus {
  open,
  pending,
  filled,
}

class DutyStatusHelper {
  static DutyStatus fromJson(String status) {
    switch (status) {
      case 'open':
        return DutyStatus.open;
      case 'pending':
        return DutyStatus.pending;
      case 'filled':
        return DutyStatus.filled;
      default:
        throw Exception('Unknown duty status: $status');
    }
  }

  static String toJson(DutyStatus status) {
    switch (status) {
      case DutyStatus.open:
        return 'open';
      case DutyStatus.pending:
        return 'pending';
      case DutyStatus.filled:
        return 'filled';
      default:
        return '';
    }
  }
}

class DutySlotForDisplay {
  final String id;
  final Hospital hospitalId;
  final Specialty requiredSpecialty;
  final DutyStatus status;
  final Doctor? assignedDoctorId;
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
      status: DutyStatusHelper.fromJson(json['status']),
      assignedDoctorId: Doctor.fromJson(json['assignedDoctorId']),
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
