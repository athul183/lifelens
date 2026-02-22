import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:lifelens/core/error/failures.dart';
import 'package:lifelens/data/crypto/crypto_isolates.dart';
import 'package:lifelens/data/repositories/vault_repository_impl.dart';
import 'package:lifelens/domain/entities/vault_item.dart';
import 'package:lifelens/domain/usecases/unlock_vault_with_fragments.dart';

void main() {
  group('VaultRepository and Use Case Architecture Tests', () {
    late Uint8List storedCiphertext;
    late Uint8List storedNonce;
    late Uint8List storedMac;
    late List<Uint8List> validShards;

    setUp(() async {
      final Uint8List originalKey = Uint8List.fromList(List<int>.generate(32, (int i) => i));
      final Uint8List plainText = Uint8List.fromList(<int>[100, 200, 255]);

      final Map<String, Uint8List> encrypted = await CryptoIsolates.encryptAesGcm(Uint8List.fromList(originalKey), Uint8List.fromList(plainText));
      storedCiphertext = encrypted['ciphertext']!;
      storedNonce = encrypted['nonce']!;
      storedMac = encrypted['mac']!;

      final Uint8List shard1 = Uint8List.fromList(List<int>.generate(32, (int i) => 255 - i));
      final Uint8List shard2 = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        shard2[i] = originalKey[i] ^ shard1[i];
      }
      validShards = <Uint8List>[shard1, shard2];
    });

    test('UnlockVaultWithFragments successfully unlocks with valid shards and yields right payload', () async {
      final VaultRepositoryImpl repo = VaultRepositoryImpl(
        storedCiphertext: storedCiphertext,
        storedNonce: storedNonce,
        storedMac: storedMac,
      );
      final UnlockVaultWithFragments usecase = UnlockVaultWithFragments(repo);

      // We must pass copies of shards since they will be zeroized
      final List<Uint8List> shardsCopy = <Uint8List>[
        Uint8List.fromList(validShards[0]),
        Uint8List.fromList(validShards[1])
      ];

      final Either<Failure, VaultItem> result = await usecase(shardsCopy);

      expect(result.isRight(), isTrue);
      result.fold(
        (Failure l) => fail('Should be right'),
        (VaultItem r) {
          expect(r.id, equals('vault_root'));
          expect(r.securePayload, equals(Uint8List.fromList(<int>[100, 200, 255])));
        },
      );

      // Assure zeroization
      expect(shardsCopy[0].every((int b) => b == 0), isTrue);
      expect(shardsCopy[1].every((int b) => b == 0), isTrue);
    });

    test('UnlockVaultWithFragments returns strictly opaque VaultAccessDenied Failure on tampered cryptography', () async {
      final VaultRepositoryImpl repo = VaultRepositoryImpl(
        storedCiphertext: storedCiphertext,
        storedNonce: storedNonce,
        storedMac: storedMac,
      );
      final UnlockVaultWithFragments usecase = UnlockVaultWithFragments(repo);

      // Tamper a shard to corrupt AES decryption key resulting in Bad MAC
      final List<Uint8List> badShards = <Uint8List>[
        Uint8List.fromList(validShards[0]),
        Uint8List.fromList(validShards[1])
      ];
      badShards[0][0] ^= 1;

      final Either<Failure, VaultItem> result = await usecase(badShards);

      expect(result.isLeft(), isTrue);
      result.fold(
        (Failure l) {
          expect(l, isA<VaultAccessDenied>());
        },
        (VaultItem r) => fail('Should be left'),
      );

      // Assure zeroization even on failure
      expect(badShards[0].every((int b) => b == 0), isTrue);
      expect(badShards[1].every((int b) => b == 0), isTrue);
    });
  });
}
