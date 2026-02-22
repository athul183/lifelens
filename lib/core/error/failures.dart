import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  const Failure();

  @override
  List<Object> get props => <Object>[];
}

class VaultAccessDenied extends Failure {
  const VaultAccessDenied();
}

// Ensure no specific internal cryptographic errors are exposed.
