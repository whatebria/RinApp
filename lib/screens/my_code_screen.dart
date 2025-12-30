import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../controller/my_code_controller.dart';
import '../providers/my_code_provider.dart';

class MyCodeScreen extends StatelessWidget {
  const MyCodeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MyCodeProvider(
      child: _MyCodeView(),
    );
  }
}

class _MyCodeView extends StatelessWidget {
  const _MyCodeView();

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("✅ Código copiado")),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<MyCodeController>();

    return Scaffold(
      appBar: AppBar(title: const Text("Mi código")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: c.loading
            ? const Center(child: CircularProgressIndicator())
            : c.error != null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Error: ${c.error}"),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: c.load,
                        child: const Text("Reintentar"),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Comparte este código con tu amigo:"),
                      const SizedBox(height: 12),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                c.profile!.friendCode,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                onPressed: () =>
                                    _copy(context, c.profile!.friendCode),
                                icon: const Icon(Icons.copy),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}
