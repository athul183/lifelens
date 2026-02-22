import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../entities/vault_item.dart';

abstract class VaultRepository {
  /// Unlocks the vault given a list of key fragments (shards)
  /// Returns [VaultItem] on success, or an opaque [VaultAccessDenied] failure on error.
  Future<Either<Failure, VaultItem>> unlockVault(List<Uint8List> keyFragments);
}
