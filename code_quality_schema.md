# Code Quality & Forensic Standards Schema

## 1. Static Analysis (The "No-Shortcut" Rule)
The project must use a strict `analysis_options.yaml` configuration.
- **strong-mode equivalents**: `strict-casts: true` and `strict-raw-types: true` (modern replacements for implicit-casts/implicit-dynamic).
- **Lints**: All `flutter_lints` plus:
  - `always_specify_types`: To ensure cryptographic buffers are explicitly typed (e.g., `Uint8List`).
  - `discarded_futures`: To prevent "fire-and-forget" async calls in security-critical paths.
  - `prefer_final_locals`: To ensure immutable data structures.

## 2. Cryptographic Implementation Standards
- **Memory Safety**: Any sensitive data (plain-text passwords or key fragments) must be stored in `Uint8List` rather than `String` to prevent them from being cached in the string pool.
- **Zero-Fill Policy**: After a decryption process is completed, the agent must implement a "wipe" function that overwrites sensitive memory buffers with zeros.
- **Isolate Separation**: The Shamir’s Secret Sharing math and AES encryption must run in a separate Background Isolate to prevent the UI thread from being "traced" by external debuggers.

## 3. Error Handling Schema (Forensic Resilience)
- **No Print Statements**: All logging must go through a custom `ForensicLogger` that encrypts logs or disables them entirely in production.
- **Opaque Errors**: Never return specific crypto errors to the UI (e.g., "Incorrect Key Fragment"). Instead, use generic "Vault Access Denied" to prevent timing attacks or enumeration.
- **Functional Error Handling**: Use the `fpdart` package. Methods should return `Either<Failure, Success>` instead of throwing exceptions.

## 4. File Architecture (The "Clean" Pattern)
Antigravity must follow Clean Architecture:
- **Data Layer**: Handles the raw encrypted file provider, cryptography operations, and repository implementations.
- **Domain Layer**: Contains the "Entities" (the Vault items) and "Use Cases" (e.g., `UnlockVaultWithFragments`).
- **Presentation Layer**: Flutter widgets that have zero knowledge of the encryption logic.
