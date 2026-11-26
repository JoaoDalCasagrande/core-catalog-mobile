import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/core_catalog_api.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/date_field.dart';
import '../settings/api_server_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, this.popOnSave = false});

  final bool popOnSave;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _avatarUrl = TextEditingController();
  String? _birthDate;

  Profile? _profile;
  bool _loading = true;
  bool _saving = false;
  String _error = '';
  String _success = '';

  @override
  void initState() {
    super.initState();
    _fullName.addListener(() => setState(() {}));
    _avatarUrl.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _fullName.dispose();
    _avatarUrl.dispose();
    super.dispose();
  }

  void _fill(Profile? p) {
    _fullName.text = p?.fullName ?? '';
    _avatarUrl.text = p?.avatarUrl ?? '';
    _birthDate = p?.birthDateOnly;
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final profile = await CoreCatalogApi.instance.myProfile();
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _fill(profile);
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.statusCode == 401
            ? e.message
            : 'Não foi possível carregar seu perfil.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() {
      _error = '';
      _success = '';
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final api = CoreCatalogApi.instance;
    final fullName = _fullName.text.trim();
    final avatar = _avatarUrl.text.trim();
    try {
      final current = _profile;
      final saved = current == null
          ? await api.createMyProfile(
              fullName: fullName,
              birthDate: _birthDate,
              avatarUrl: avatar,
            )
          : await api.updateProfile(
              current.id,
              fullName: fullName,
              birthDate: _birthDate,
              avatarUrl: avatar,
            );
      if (!mounted) return;
      if (widget.popOnSave) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _profile = saved;
        _fill(saved);
        _success = 'Perfil salvo.';
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _logout() async {
    await Session.instance.signOut();
    if (!mounted) return;
    if (widget.popOnSave) Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.instance.user;
    final previewName =
        _fullName.text.trim().isEmpty ? 'Seu perfil' : _fullName.text.trim();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Meu perfil', style: AppText.sectionTitle),
        actions: [
          IconButton(
            tooltip: 'Sair',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: appCardDecoration(color: AppColors.bgPage),
              child: Column(
                children: [
                  ProfileAvatar(
                    name: previewName,
                    url: _avatarUrl.text,
                    size: 88,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    previewName,
                    textAlign: TextAlign.center,
                    style: AppText.sectionTitle,
                  ),
                  if (user != null) ...[
                    const SizedBox(height: 2),
                    Text(user.email, style: AppText.secondary),
                  ],
                  const SizedBox(height: 8),
                  InfoRow(label: 'Nascimento', value: formatDateBr(_birthDate)),
                  InfoRow(
                    label: 'Situação',
                    value: _loading
                        ? 'Carregando...'
                        : (_profile != null ? 'Perfil criado' : 'Sem perfil'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PageHeader(
              title: 'Meu perfil',
              subtitle: _profile != null
                  ? 'Atualize seus dados. Eles aparecem nas builds que você montar.'
                  : 'Crie seu perfil para montar builds. Cada conta tem um único perfil.',
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty) ...[
              AlertBanner(_error),
              const SizedBox(height: 12),
            ],
            if (_success.isNotEmpty) ...[
              AlertBanner(_success, isError: false),
              const SizedBox(height: 12),
            ],
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _fullName,
                    enabled: !_loading,
                    maxLength: 120,
                    textCapitalization: TextCapitalization.words,
                    decoration: appInputDecoration(
                      label: 'Nome completo',
                      hint: 'Nome completo',
                    ),
                    validator: (v) {
                      final name = (v ?? '').trim();
                      if (name.length < 2) {
                        return 'Informe o nome completo (mínimo 2 caracteres).';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  DateField(
                    label: 'Data de nascimento',
                    value: _birthDate,
                    enabled: !_loading,
                    onChanged: (v) => setState(() => _birthDate = v),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _avatarUrl,
                    enabled: !_loading,
                    keyboardType: TextInputType.url,
                    autocorrect: false,
                    maxLength: 500,
                    decoration: appInputDecoration(
                      label: 'URL do avatar',
                      hint: 'https://...',
                      helper: 'Opcional. Cole o link de uma imagem.',
                    ),
                    validator: validateOptionalUrl,
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: _profile != null ? 'Salvar alterações' : 'Criar perfil',
                    busyLabel: 'Salvando...',
                    busy: _saving,
                    onPressed: _loading ? null : _save,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            const Text('Conta', style: AppText.sectionTitle),
            const SizedBox(height: 8),
            Container(
              decoration: appCardDecoration(),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.alternate_email),
                    title: Text(user?.name ?? 'Usuário'),
                    subtitle: Text(user?.email ?? ''),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.dns_outlined),
                    title: const Text('Servidor da API'),
                    subtitle: Text(Session.instance.baseUrl),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await showApiServerDialog(context);
                      if (mounted) setState(() {});
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading:
                        const Icon(Icons.logout, color: AppColors.alertText),
                    title: const Text('Sair',
                        style: TextStyle(color: AppColors.alertText)),
                    onTap: _logout,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String? validateOptionalUrl(String? value) {
  final text = (value ?? '').trim();
  if (text.isEmpty) return null;
  final uri = Uri.tryParse(text);
  if (uri == null ||
      !(uri.scheme == 'http' || uri.scheme == 'https') ||
      uri.host.isEmpty) {
    return 'Informe um link válido (http:// ou https://).';
  }
  return null;
}
