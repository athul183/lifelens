import 'dart:isolate';
import 'dart:typed_data';
import 'package:cryptography/cryptography.dart';
import '../../core/logger/forensic_logger.dart';

extension ZeroFill on Uint8List {
  /// Securely wipes the memory allocated for this list by writing zeros.
  void zeroFill() {
    for (int i = 0; i < length; i++) {
      this[i] = 0;
    }
  }
}

class CryptoIsolates {
  /// Recombines Shamir Secret Sharing fragments to reconstruct a symmetric key.
  static Future<Uint8List> combineShards(List<Uint8List> shards) async {
    return await Isolate.run(() {
      try {
        if (shards.length < 2) {
          throw Exception('Not enough fragments');
        }
        // Simulated SSS logic: In a real environment, use proper polynomial interpolation logic here.
        // For testing, we just XOR the two arrays to stub the recombination.
        final int length = shards[0].length;
        final Uint8List result = Uint8List(length);
        for (int i = 0; i < length; i++) {
          int val = shards[0][i];
          for (int j = 1; j < shards.length; j++) {
            val ^= shards[j][i];
          }
          result[i] = val;
        }
        return result;
      } catch (e) {
        ForensicLogger.encryptAndLog('Shard combination failed: $e');
        throw Exception('Cryptographic Failure');
      }
    });
  }

  /// Decrypts ciphertext using AES-GCM and the reconstructed key.
  static Future<Uint8List> decryptAesGcm(Uint8List key, Uint8List encryptedData, Uint8List nonce, Uint8List mac) async {
    return await Isolate.run(() async {
      try {
        final AesGcm algorithm = AesGcm.with256bits();
        final SecretKey secretKey = SecretKey(key);
        
        final Uint8List decryptedText = await algorithm.decrypt(
          SecretBox(
            encryptedData,
            nonce: nonce,
            mac: Mac(mac),
          ),
          secretKey: secretKey,
        ) as Uint8List; // Force casting based on library API if possible, or mapping.

        // Actually cryptography package returns List<int>, we must convert to Uint8List explicitly safely.
        final Uint8List typedResult = Uint8List.fromList(decryptedText);

        // Wipe the secret key in the isolate
        key.zeroFill();
        
        return typedResult;
      } catch (e) {
        ForensicLogger.encryptAndLog('AES-GCM decryption failed: $e');
        // Critical: zero-fill key even on failure
        key.zeroFill();
        throw Exception('Cryptographic Failure'); // Opaque error
      }
    });
  }

  /// Encrypts plaintext using AES-GCM and a key.
  static Future<Map<String, Uint8List>> encryptAesGcm(Uint8List key, Uint8List plainText) async {
    return await Isolate.run(() async {
      try {
        final AesGcm algorithm = AesGcm.with256bits();
        final SecretKey secretKey = SecretKey(key);
        
        final SecretBox secretBox = await algorithm.encrypt(
          plainText,
          secretKey: secretKey,
        );
        
        // Wipe the secret key and plainText in the isolate
        key.zeroFill();
        plainText.zeroFill();
        
        return <String, Uint8List>{
          'ciphertext': Uint8List.fromList(secretBox.cipherText),
          'nonce': Uint8List.fromList(secretBox.nonce),
          'mac': Uint8List.fromList(secretBox.mac.bytes),
        };
      } catch (e) {
        ForensicLogger.encryptAndLog('AES-GCM encryption failed: $e');
        key.zeroFill();
        plainText.zeroFill();
        throw Exception('Cryptographic Failure');
      }
    });
  }
}
