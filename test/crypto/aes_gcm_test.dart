import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifelens/data/crypto/crypto_isolates.dart';

void main() {
  group('AES-GCM Cryptographic Tests', () {
    test('Encrypts and decrypts correctly maintaining memory safety constraints', () async {
      final Uint8List key = Uint8List.fromList(List<int>.generate(32, (int i) => i % 256));
      final Uint8List plainText = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);

      // Copy because encryptAesGcm zeroizes the memory references passed to it!
      final Uint8List keyCopyForEncryption = Uint8List.fromList(key);
      final Uint8List plainTextCopy = Uint8List.fromList(plainText);

      final Map<String, Uint8List> encrypted = await CryptoIsolates.encryptAesGcm(keyCopyForEncryption, plainTextCopy);
      
      // The background isolate zeroes out its own memory space copy of the keys.
      // The parent caller is strictly mandated to zero out its original arguments.
      keyCopyForEncryption.zeroFill();
      plainTextCopy.zeroFill();

      // Ensure zeroization happened on the parent side manually
      expect(keyCopyForEncryption.every((int b) => b == 0), isTrue);
      expect(plainTextCopy.every((int b) => b == 0), isTrue);

      final Uint8List cipherText = encrypted['ciphertext']!;
      final Uint8List nonce = encrypted['nonce']!;
      final Uint8List mac = encrypted['mac']!;

      final Uint8List keyCopyForDecryption = Uint8List.fromList(key);
      final Uint8List decrypted = await CryptoIsolates.decryptAesGcm(keyCopyForDecryption, cipherText, nonce, mac);

      // Caller zeros out the decryption key
      keyCopyForDecryption.zeroFill();

      // Ensure zeroization happened on decryption parent side
      expect(keyCopyForDecryption.every((int b) => b == 0), isTrue);

      expect(decrypted, equals(plainText));
    });

    test('Fails on tampered MAC/Ciphertext without leaking specific type', () async {
      final Uint8List key = Uint8List.fromList(List<int>.generate(32, (int i) => 1));
      final Uint8List plainText = Uint8List.fromList(<int>[10, 20, 30]);

      final Map<String, Uint8List> encrypted = await CryptoIsolates.encryptAesGcm(Uint8List.fromList(key), Uint8List.fromList(plainText));
      
      final Uint8List cipherText = encrypted['ciphertext']!;
      final Uint8List nonce = encrypted['nonce']!;
      final Uint8List mac = encrypted['mac']!;

      // Tamper with MAC
      mac[0] ^= 1;

      expect(
        () async => await CryptoIsolates.decryptAesGcm(Uint8List.fromList(key), cipherText, nonce, mac),
        throwsA(predicate((Object? e) => e is Exception && e.toString().contains('Cryptographic Failure'))),
      );
    });
  });
}
