abstract class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network connection failed. Please check your connection.']);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, [this.statusCode]);
}

class InventoryConflictFailure extends Failure {
  final String dishName;
  final int requestedCount;
  final int availableCount;

  const InventoryConflictFailure({
    required this.dishName,
    required this.requestedCount,
    required this.availableCount,
    String message = 'The requested item count is no longer available.',
  }) : super(message);
}

class InvalidTransitionFailure extends Failure {
  final String currentStatus;
  final String attemptedStatus;

  const InvalidTransitionFailure({
    required this.currentStatus,
    required this.attemptedStatus,
    String message = 'Invalid order status transition requested.',
  }) : super(message);
}

class DuplicateOrderFailure extends Failure {
  const DuplicateOrderFailure([super.message = 'Order with this idempotency key was already submitted.']);
}
