import 'dart:typed_data';
import 'package:equatable/equatable.dart';

class VaultItem extends Equatable {
  final String id;
  // Payload is strictly kept as Uint8List for memory safety. Do not convert to String unless displaying immediately.
  final Uint8List securePayload;

  const VaultItem({
    required this.id,
    required this.securePayload,
  });

  @override
  List<Object> get props => <Object>[id, securePayload];
}
