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
  GameOperationException(super.message, {super.code, super.cause});
}

/// Friend/social operation failures
class FriendOperationException extends AppException {
  FriendOperationException(super.message, {super.code, super.cause});
}

/// Chat operation failures
class ChatOperationException extends AppException {
  ChatOperationException(super.message, {super.code, super.cause});
}

/// Permission/authorization failures
class PermissionException extends AppException {
  PermissionException(super.message, {super.code, super.cause});
}

/// Network/connectivity failures
class NetworkException extends AppException {
  NetworkException(super.message, {super.code, super.cause});
}

/// Join request operation failures
class JoinRequestException extends AppException {
  JoinRequestException(super.message, {super.code, super.cause});
}

/// Block operation failures
class BlockOperationException extends AppException {
  BlockOperationException(super.message, {super.code, super.cause});
}
