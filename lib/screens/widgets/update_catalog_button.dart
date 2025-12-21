import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UpdateCatalogButton extends StatefulWidget {
  const UpdateCatalogButton({super.key});

  @override
  State<UpdateCatalogButton> createState() => _UpdateCatalogButtonState();
}

class _UpdateCatalogButtonState extends State<UpdateCatalogButton> {
  bool _loading = false;
  String _status = '';

  Future<void> _run() async {
    setState(() {
      _loading = true;
      _status = '';
    });

    try {
      final res = await Supabase.instance.client.functions.invoke(
        'hydrate_openlibrary',
        body: {'limit': 100},
      );

      setState(() {
        _status = res.data?.toString() ?? 'OK';
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: _loading ? null : _run,
          child: Text(_loading ? 'Actualizando...' : 'Actualizar datos'),
        ),
        if (_status.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _status,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}
