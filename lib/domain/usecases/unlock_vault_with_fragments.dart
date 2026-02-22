import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../entities/vault_item.dart';
import '../repositories/vault_repository.dart';

class UnlockVaultWithFragments {
  final VaultRepository repository;

  const UnlockVaultWithFragments(this.repository);

  Future<Either<Failure, VaultItem>> call(List<Uint8List> fragments) async {
    if (fragments.length < 2) {
      // Require at least 2 fragments based on standard Shamir setup for security, simulating minimum threshold
      return const Left<Failure, VaultItem>(VaultAccessDenied());
    }
    return repository.unlockVault(fragments);
  }
}
