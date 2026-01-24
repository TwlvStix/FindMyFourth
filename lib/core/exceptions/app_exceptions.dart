/// Base exception for all app-specific errors
class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic cause;

  AppException(this.message, {this.code, this.cause});

  @override
  String toString() =>
      'AppException: $message${code != null ? " (code: $code)" : ""}';
}

/// Game operation failures
class GameOperationException extends AppException {
  GameOperationException(String message, {String? code, dynamic cause})
      : super(message, code: code, cause: cause);
}

/// Friend/social operation failures
class FriendOperationException extends AppException {
  FriendOperationException(String message, {String? code, dynamic cause})
      : super(message, code: code, cause: cause);
}

/// Chat operation failures
class ChatOperationException extends AppException {
  ChatOperationException(String message, {String? code, dynamic cause})
      : super(message, code: code, cause: cause);
}

/// Permission/authorization failures
class PermissionException extends AppException {
  PermissionException(String message, {String? code, dynamic cause})
      : super(message, code: code, cause: cause);
}

/// Network/connectivity failures
class NetworkException extends AppException {
  NetworkException(String message, {String? code, dynamic cause})
      : super(message, code: code, cause: cause);
}
