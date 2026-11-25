import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/core_catalog_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../settings/api_server_dialog.dart';
import 'auth_preview.dart';
import 'login_screen.dart' show validateEmail;

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _loading = false;
  String _error = '';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      // O register já devolve o token, então o usuário entra direto
      await CoreCatalogApi.instance.register(
        _name.text.trim(),
        _email.text.trim(),
        _password.text,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Core Catalog', style: AppText.sectionTitle),
        actions: const [ApiServerButton()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            const PageHeader(
              title: 'Criar conta',
              subtitle:
                  'Monte builds dentro do orçamento e guarde todas elas em um só lugar.',
            ),
            const SizedBox(height: 24),
            if (_error.isNotEmpty) ...[
              AlertBanner(_error),
              const SizedBox(height: 16),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _name,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.name],
                    textInputAction: TextInputAction.next,
                    maxLength: 100,
                    decoration: appInputDecoration(
                      label: 'Nome',
                      hint: 'Nome completo',
                      helper: 'Entre 3 e 100 caracteres',
                    ),
                    validator: (v) {
                      final name = (v ?? '').trim();
                      if (name.length < 3 || name.length > 100) {
                        return 'O nome deve ter entre 3 e 100 caracteres.';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    decoration: appInputDecoration(
                      label: 'E-mail',
                      hint: 'nome@exemplo.com',
                    ),
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _password,
                    obscureText: !_showPassword,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: appInputDecoration(
                      label: 'Senha',
                      hint: '••••••',
                      helper: 'Mínimo de 6 caracteres',
                      suffixIcon: IconButton(
                        tooltip:
                            _showPassword ? 'Ocultar senha' : 'Mostrar senha',
                        icon: Icon(_showPassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined),
                        onPressed: () =>
                            setState(() => _showPassword = !_showPassword),
                      ),
                    ),
                    validator: (v) => (v ?? '').length < 6
                        ? 'A senha deve ter no mínimo 6 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Criar conta',
                    busyLabel: 'Criando conta...',
                    busy: _loading,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Já tem conta?', style: AppText.subtitle),
                TextButton(
                  onPressed:
                      _loading ? null : () => Navigator.of(context).pop(false),
                  child: const Text('Entrar'),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const AuthPreview(),
          ],
        ),
      ),
    );
  }
}
