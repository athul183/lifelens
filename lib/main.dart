import 'package:flutter/material.dart';
import 'presentation/pages/vault_page.dart';

void main() {
  runApp(const ForensicVaultApp());
}

class ForensicVaultApp extends StatelessWidget {
  const ForensicVaultApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Forensic Vault',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const VaultPage(),
    );
  }
}
