import 'package:flutter/material.dart';

import '../../config/api_config.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';

/// Ícone que abre a configuração do endereço da API.
class ApiServerButton extends StatelessWidget {
  const ApiServerButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Servidor da API',
      icon: const Icon(Icons.dns_outlined),
      onPressed: () => showApiServerDialog(context),
    );
  }
}

/// Permite trocar o endereço da API sem recompilar
/// (ex.: celular físico apontando para o IP do computador: http://192.168.0.10:3001).
Future<void> showApiServerDialog(BuildContext context) async {
  final controller = TextEditingController(text: Session.instance.baseUrl);
  String? error;

  final result = await showDialog<String>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Servidor da API'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Endereço onde o back-end core-catalog está rodando (porta 3001).',
              style: AppText.secondary,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.url,
              autocorrect: false,
              decoration: appInputDecoration(
                label: 'URL da API',
                hint: 'http://192.168.0.10:3001',
              ).copyWith(errorText: error),
            ),
            const SizedBox(height: 8),
            Text(
              'Padrão neste aparelho: ${ApiConfig.defaultBaseUrl}',
              style: AppText.secondary,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(''),
            child: const Text('Usar padrão'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = controller.text.trim();
              final uri = Uri.tryParse(value);
              if (uri == null ||
                  !(uri.scheme == 'http' || uri.scheme == 'https') ||
                  uri.host.isEmpty) {
                setState(() => error = 'Use o formato http://endereço:porta');
                return;
              }
              Navigator.of(context).pop(value);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );

  if (result == null) return;
  await Session.instance.setBaseUrl(result.isEmpty ? null : result);
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('API: ${Session.instance.baseUrl}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
