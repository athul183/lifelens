# Forensic Secure Vault (Project LifeLens)

A Flutter application demonstrating Top-Notch forensic-grade security patterns for sensitive data storage and retrieval. This project implements "Zero-Knowledge" principles using Clean Architecture, Functional Programming, and strict static analysis.

## Key Features

- **Strict Static Analysis**: Enforces Top-Notch code quality using customized `analysis_options.yaml` (`strict-casts`, `strict-raw-types`, `always_specify_types`, `prefer_final_locals`).
- **Memory Safety**: Uses `Uint8List` for all sensitive cryptographic materials, preventing secrets from leaking into Dart's immutable string pool.
- **Zero-Fill Policy**: Explicitly overrides and writes `0`s to sensitive memory buffers the moment decryption completes (`Uint8List.zeroFill()`).
- **Isolate Separation**: Executes heavy cryptographic operations (AES-GCM decryption and Shamir's Secret Sharing recombination) in background isolates to prevent main-thread memory tracing.
- **Functional Error Handling**: Uses the `fpdart` package returning opaque `Either<Failure, Success>` to prevent side-channel timing attacks or specific cryptographic error exposure.
- **Clean Architecture**: Strictly separates cryptographic complexities (Data layer) from UI state (Presentation layer) using Domain entities (`VaultItem`) and use cases.

## Getting Started

### Prerequisites
- Flutter SDK `^3.7.2`
- Dart SDK `^3.0.0`

### Installation
1. Clone the repository.
2. Install dependencies:
```sh
flutter pub get
```

### Running the App
Run the application on your desired platform (iOS/Android/Web/Desktop):
```sh
flutter run
```

### Forensic Verification (Pre-Commit Hook)
Before committing any code, you **must** pass the forensic CI threshold. We provide a shell script to automate this:
```sh
./pre-commit.sh
```
This script ensures:
1. `flutter analyze` returns 0 issues (strictly checked by `analysis_options.yaml`).
2. Crypto Isolate Fragment Recombination tests pass.
3. AES-GCM Integrity tests pass.
4. Vault Architecture end-to-end repository tests pass.

## Project Structure (Clean Architecture)
- `lib/core/`: Error failures and Forensic Loggers.
- `lib/data/`: `VaultRepositoryImpl` and remote `CryptoIsolates`.
- `lib/domain/`: `VaultItem` entities and `UnlockVaultWithFragments` use cases.
- `lib/presentation/`: The main User Interface (`VaultPage`).

## Dependencies
- `fpdart`: Functional programming primitives (`Either`, `Left`, `Right`).
- `cryptography`: Pure-Dart implementation of modern cryptographic algorithms (`AesGcm`).
- `equatable`: Value-based equality for domain entities and failures.
