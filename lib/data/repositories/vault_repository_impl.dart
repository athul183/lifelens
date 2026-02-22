import 'dart:typed_data';
import 'package:fpdart/fpdart.dart';
import '../../core/error/failures.dart';
import '../../core/logger/forensic_logger.dart';
import '../../domain/entities/vault_item.dart';
import '../../domain/repositories/vault_repository.dart';
import '../crypto/crypto_isolates.dart';

class VaultRepositoryImpl implements VaultRepository {
  // In a real application, these would come from secure local storage or network
  // Providing stubs to fulfill the repository contract.
  final Uint8List storedCiphertext;
  final Uint8List storedNonce;
  final Uint8List storedMac;

  const VaultRepositoryImpl({
    required this.storedCiphertext,
    required this.storedNonce,
    required this.storedMac,
  });

  @override
  Future<Either<Failure, VaultItem>> unlockVault(List<Uint8List> keyFragments) async {
    try {
      if (keyFragments.isEmpty) {
        return const Left<Failure, VaultItem>(VaultAccessDenied());
      }
      
      // 1. Recombine keys in isolate
      final Uint8List reconstructedKey = await CryptoIsolates.combineShards(keyFragments);
      
      // 2. Decrypt in isolate
      final Uint8List decryptedData = await CryptoIsolates.decryptAesGcm(
        reconstructedKey,
        storedCiphertext,
        storedNonce,
        storedMac,
      );
      
      // 3. Wipe memory of key shards received
      for (final Uint8List shard in keyFragments) {
        shard.zeroFill();
      }
      
      // Keep result stored safely in entity
      return Right<Failure, VaultItem>(
        VaultItem(
          id: 'vault_root',
          securePayload: decryptedData,
        ),
      );
    } catch (e) {
      ForensicLogger.encryptAndLog('Unlock failure occurred');
      
      // For security, wipe fragments irrespective of exception context
      for (final Uint8List shard in keyFragments) {
        try {
          shard.zeroFill();
        } catch (_) {
          // Ignore if already wiped
        }
      }

      // Hide all details, just return exact same opaque error
      return const Left<Failure, VaultItem>(VaultAccessDenied());
    }
  }
}
