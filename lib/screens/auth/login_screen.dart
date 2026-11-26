import 'package:flutter/material.dart';

import '../../services/api_client.dart';
import '../../services/core_catalog_api.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../settings/api_server_dialog.dart';
import 'auth_preview.dart';
import 'register_screen.dart';

Future<bool> ensureLoggedIn(BuildContext context) async {
  if (Session.instance.isAuthenticated) return true;
  final ok = await Navigator.of(context).push<bool>(
    MaterialPageRoute(builder: (_) => const LoginScreen()),
  );
  return ok == true && Session.instance.isAuthenticated;
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  bool _loading = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    if (Session.instance.expired) {
      _error = 'Sua sessão expirou. Entre novamente.';
    }
  }

  @override
  void dispose() {
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
      await CoreCatalogApi.instance.login(_email.text.trim(), _password.text);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openRegister() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
    if (created == true && mounted) Navigator.of(context).pop(true);
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
              title: 'Entrar',
              subtitle: 'Acesse sua conta para montar e salvar builds.',
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
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: appInputDecoration(
                      label: 'Senha',
                      hint: '••••••••',
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
                        ? 'A senha tem no mínimo 6 caracteres.'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(
                    label: 'Entrar',
                    busyLabel: 'Entrando...',
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
                const Text('Ainda não tem conta?', style: AppText.subtitle),
                TextButton(
                  onPressed: _loading ? null : _openRegister,
                  child: const Text('Criar conta'),
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

String? validateEmail(String? value) {
  final email = (value ?? '').trim();
  if (email.isEmpty) return 'Informe o e-mail.';
  if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
    return 'Informe um e-mail válido.';
  }
  return null;
}
