# Project Proposal: Secure Forensic Vault Application

## Overview
This proposal outlines the implementation of a highly secure, forensic-grade Vault application in Flutter, centered around "Zero-Knowledge" principles, Shamir's Secret Sharing (SSS), and AES-GCM encryption.

## Objectives
1. **Uncompromising Code Quality**: Implementing a `Top Notch` threshold using strict static analysis, functional programming (`fpdart`), and immutable states.
2. **Forensic Resilience**: Preventing side-channel attacks, memory leaks, and timing attacks through Isolate separation, zero-filled buffers (`Uint8List`), and opaque error outputs.
3. **Clean Architecture**: Structuring the app into decoupled layers (Domain, Data, Presentation) to isolate cryptographic complexities from the UI.
4. **Automated Verification**: Enforcing rules via pre-commit hooks that strictly run `flutter analyze` and `flutter test`.

## Core Deliverables
1. **Strict Analysis**: A comprehensive `analysis_options.yaml` enforcing types, tracking futures, and preferring finals.
2. **Vault Implementation**:
   - `VaultRepository` definition in the Domain layer.
   - `VaultRepositoryImpl` connecting to local storage and cryptographic routines in the Data layer.
   - Separate Isolate workers for AES decryption and SSS fragment recombination.
3. **Test Suites**:
   - Suite 1: Key Splitting Validation.
   - Suite 2: Fragment Recombination Integrity.
   - Suite 3: AES-GCM Cryptographic Soundness.
4. **Tooling**: A `pre-commit.sh` enforcing CI/CD-like checks locally.
