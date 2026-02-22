#!/usr/bin/env bash

# Forensic Vault Pre-commit Hook
# Enforces strictly that no code is committed unless it passes the Top-Notch static analysis threshold
# and all cryptographic verification tests.

set -e

echo "[Forensic Vault] Running strict analyzer..."
flutter analyze

echo "[Forensic Vault] Running verification test suites..."
flutter test test/crypto/sss_test.dart
flutter test test/crypto/aes_gcm_test.dart
flutter test test/architecture/vault_repository_test.dart

echo "[Forensic Vault] All tests passed. System is Forensic-Ready."
