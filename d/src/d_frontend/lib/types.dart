

abstract class Status {}

class Response implements Status {
  // Response implementation
}

class ExceptionalFailure implements Status {
  // ExceptionalFailure implementation
}

class Error implements Status {
  // Error implementation
}


enum UserRole {
  doctor,
  hospital,
}
