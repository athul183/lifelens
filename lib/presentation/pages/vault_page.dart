import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fpdart/fpdart.dart' hide State;

import '../../core/error/failures.dart';
import '../../data/crypto/crypto_isolates.dart';
import '../../data/repositories/vault_repository_impl.dart';
import '../../domain/entities/vault_item.dart';
import '../../domain/usecases/unlock_vault_with_fragments.dart';

class VaultPage extends StatefulWidget {
  const VaultPage({super.key});

  @override
  State<VaultPage> createState() => _VaultPageState();
}

class _VaultPageState extends State<VaultPage> {
  final TextEditingController _shard1Controller = TextEditingController();
  final TextEditingController _shard2Controller = TextEditingController();

  bool _isGenerating = false;
  bool _isUnlocking = false;
  String? _errorMessage;
  String? _decryptedPayload;

  VaultRepositoryImpl? _repository;

  String? _generatedShard1;
  String? _generatedShard2;

  // Forensic Theme Colors
  final Color _bg = const Color(0xFF0A0A0A);
  final Color _surface = const Color(0xFF171717);
  final Color _accent = const Color(0xFF10B981);
  final Color _error = const Color(0xFFEF4444);
  final Color _textMain = const Color(0xFFF3F4F6);
  final Color _textMuted = const Color(0xFF9CA3AF);

  @override
  void dispose() {
    _shard1Controller.dispose();
    _shard2Controller.dispose();
    super.dispose();
  }

  Future<void> _generateDemoVault() async {
    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _decryptedPayload = null;
      _generatedShard1 = null;
      _generatedShard2 = null;
    });

    try {
      final Uint8List originalKey =
          Uint8List.fromList(List<int>.generate(32, (int i) => i % 256));
      final Uint8List plainText = utf8.encoder.convert('TOP SECRET: Project Antigravity Forensic Vault is online.');

      final Map<String, Uint8List> encrypted = await CryptoIsolates.encryptAesGcm(
        Uint8List.fromList(originalKey), // pass copy since it gets zeroed
        Uint8List.fromList(plainText),
      );

      final Uint8List shard1Bytes =
          Uint8List.fromList(List<int>.generate(32, (int i) => (i * 7) % 256));
      final Uint8List shard2Bytes = Uint8List(32);
      for (int i = 0; i < 32; i++) {
        shard2Bytes[i] = originalKey[i] ^ shard1Bytes[i];
      }

      _repository = VaultRepositoryImpl(
        storedCiphertext: encrypted['ciphertext']!,
        storedNonce: encrypted['nonce']!,
        storedMac: encrypted['mac']!,
      );

      setState(() {
        _generatedShard1 = base64Encode(shard1Bytes);
        _generatedShard2 = base64Encode(shard2Bytes);
        _isGenerating = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'System Failure: Generation aborted.';
        _isGenerating = false;
      });
    }
  }

  Future<void> _unlockVault() async {
    if (_repository == null) {
      setState(() => _errorMessage = 'Setup the Vault first by pressing Initialize.');
      return;
    }

    setState(() {
      _isUnlocking = true;
      _errorMessage = null;
      _decryptedPayload = null;
    });

    try {
      final Uint8List s1 = base64Decode(_shard1Controller.text.trim());
      final Uint8List s2 = base64Decode(_shard2Controller.text.trim());

      final UnlockVaultWithFragments usecase = UnlockVaultWithFragments(_repository!);
      final Either<Failure, VaultItem> result = await usecase(<Uint8List>[s1, s2]);

      setState(() {
        _isUnlocking = false;
        result.fold(
          (Failure l) {
            _errorMessage = 'ACCESS DENIED: Invalid Fragments';
          },
          (VaultItem r) {
            _decryptedPayload = utf8.decode(r.securePayload);
            r.securePayload.zeroFill(); // wipe memory
          },
        );
      });
    } catch (e) {
      setState(() {
        _isUnlocking = false;
        _errorMessage = 'ACCESS DENIED: Format Error';
      });
    }
  }

  Widget _buildSetupSection() {
    if (_repository != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _accent.withAlpha(128)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.check_circle_outline, color: _accent),
                const SizedBox(width: 8),
                Text('Vault Initialized', style: TextStyle(color: _accent, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 16),
            Text('Shard 1 (Distribute to Party A):', style: TextStyle(color: _textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            SelectableText(_generatedShard1 ?? '', style: TextStyle(color: _textMain, fontFamily: 'monospace')),
            const SizedBox(height: 12),
            Text('Shard 2 (Distribute to Party B):', style: TextStyle(color: _textMuted, fontSize: 12)),
            const SizedBox(height: 4),
            SelectableText(_generatedShard2 ?? '', style: TextStyle(color: _textMain, fontFamily: 'monospace')),
          ],
        ),
      );
    }

    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: _accent,
        foregroundColor: _bg,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _isGenerating ? null : _generateDemoVault,
      icon: _isGenerating ? const CircularProgressIndicator() : const Icon(Icons.admin_panel_settings),
      label: const Text('INITIALIZE ZERO-KNOWLEDGE VAULT', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        title: Text('FORENSIC SECURE VAULT', style: TextStyle(color: _textMain, letterSpacing: 2, fontWeight: FontWeight.w600)),
        centerTitle: true,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: _surface, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildSetupSection(),
              const SizedBox(height: 32),
              
              const Text('SYSTEM ACCESS', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              
              TextField(
                controller: _shard1Controller,
                style: TextStyle(color: _textMain, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: 'INPUT SHARD 1',
                  labelStyle: TextStyle(color: _textMuted),
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.key, color: _textMuted),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _shard2Controller,
                style: TextStyle(color: _textMain, fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: 'INPUT SHARD 2',
                  labelStyle: TextStyle(color: _textMuted),
                  filled: true,
                  fillColor: _surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                  prefixIcon: Icon(Icons.key, color: _textMuted),
                ),
              ),
              const SizedBox(height: 24),
              
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: _error.withAlpha(25),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _error),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.warning_amber_rounded, color: _error),
                      const SizedBox(width: 12),
                      Expanded(child: Text(_errorMessage!, style: TextStyle(color: _error, fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _surface,
                  foregroundColor: _textMain,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: BorderSide(color: _accent),
                  ),
                ),
                onPressed: _isUnlocking ? null : _unlockVault,
                child: _isUnlocking 
                  ? CircularProgressIndicator(color: _accent)
                  : Text('DECRYPT PAYLOAD', style: TextStyle(fontSize: 16, letterSpacing: 2, color: _accent, fontWeight: FontWeight.bold)),
              ),

              if (_decryptedPayload != null) ...<Widget>[
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _accent.withAlpha(13),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _accent),
                  ),
                  child: Column(
                    children: <Widget>[
                      const Icon(Icons.lock_open, color: Colors.greenAccent, size: 48),
                      const SizedBox(height: 16),
                      const Text('DECRYPTED PAYLOAD', style: TextStyle(color: Colors.greenAccent, letterSpacing: 2, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Text(
                        _decryptedPayload!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white, fontSize: 16, height: 1.5),
                      ),
                    ],
                  ),
                )
              ]
            ],
          ),
        ),
      ),
    );
  }
}
