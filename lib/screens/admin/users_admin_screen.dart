import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/core_catalog_api.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import '../auth/login_screen.dart' show validateEmail;

/// Usuários: cadastrar, editar e excluir contas (CRUD de /users).
class UsersAdminScreen extends StatefulWidget {
  const UsersAdminScreen({super.key});

  @override
  State<UsersAdminScreen> createState() => _UsersAdminScreenState();
}

class _UsersAdminScreenState extends State<UsersAdminScreen> {
  List<AppUser> _users = [];
  bool _loading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await CoreCatalogApi.instance.users();
      if (mounted) setState(() => _users = data);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.statusCode == 401
            ? e.message
            : 'Não foi possível carregar os usuários. Verifique a API.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([AppUser? user]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => UserFormScreen(user: user)),
    );
    if (saved == true && mounted) {
      showSnack(context, user == null ? 'Usuário cadastrado.' : 'Usuário atualizado.');
      _load();
    }
  }

  Future<void> _remove(AppUser user) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir usuário',
      message: 'Excluir este usuário? O perfil e as builds dele também serão apagados.',
    );
    if (!ok || !mounted) return;
    setState(() => _error = '');
    try {
      await CoreCatalogApi.instance.deleteUser(user.id);
      if (!mounted) return;
      // Excluiu a própria conta: a sessão deixa de valer
      if (Session.instance.user?.id == user.id) {
        await Session.instance.signOut();
        if (mounted) Navigator.of(context).pop();
        return;
      }
      showSnack(context, 'Usuário excluído.');
      _load();
    } on ApiException {
      if (mounted) setState(() => _error = 'Não foi possível excluir o usuário.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Usuários', style: AppText.sectionTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('Novo usuário'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            if (_error.isNotEmpty) ...[
              AlertBanner(_error),
              const SizedBox(height: 12),
            ],
            if (_loading && _users.isEmpty)
              const EmptyState('Carregando usuários...', loading: true)
            else if (_users.isEmpty)
              const EmptyState('Nenhum usuário cadastrado.')
            else
              Container(
                decoration: appCardDecoration(),
                child: Column(
                  children: [
                    for (var i = 0; i < _users.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        leading: ProfileAvatar(name: _users[i].name, size: 40),
                        title: Text(_users[i].name, style: AppText.label),
                        subtitle: Text(_users[i].email),
                        trailing: RowActions(
                          onEdit: () => _openForm(_users[i]),
                          onDelete: () => _remove(_users[i]),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Formulário de usuário. No cadastro pede senha; na edição só nome e e-mail.
class UserFormScreen extends StatefulWidget {
  const UserFormScreen({super.key, this.user});

  final AppUser? user;

  @override
  State<UserFormScreen> createState() => _UserFormScreenState();
}

class _UserFormScreenState extends State<UserFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.user?.name ?? '');
  late final _email = TextEditingController(text: widget.user?.email ?? '');
  final _password = TextEditingController();
  bool _saving = false;
  String _error = '';

  bool get _isEditing => widget.user != null;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = '';
    });
    final api = CoreCatalogApi.instance;
    try {
      if (_isEditing) {
        await api.updateUser(
            widget.user!.id, _name.text.trim(), _email.text.trim());
      } else {
        // A senha vai em texto puro; o back-end gera o hash
        await api.createUser(
            _name.text.trim(), _email.text.trim(), _password.text);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        title: Text(_isEditing ? 'Editar usuário' : 'Novo usuário',
            style: AppText.sectionTitle),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (_error.isNotEmpty) ...[
                AlertBanner(_error),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                maxLength: 100,
                decoration: appInputDecoration(
                    label: 'Nome', hint: 'Nome completo'),
                validator: (v) {
                  final name = (v ?? '').trim();
                  return name.length < 3 || name.length > 100
                      ? 'O nome deve ter entre 3 e 100 caracteres.'
                      : null;
                },
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                autocorrect: false,
                decoration: appInputDecoration(
                    label: 'E-mail', hint: 'nome@exemplo.com'),
                validator: validateEmail,
              ),
              if (!_isEditing) ...[
                const SizedBox(height: 20),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: appInputDecoration(
                    label: 'Senha',
                    hint: '••••••',
                    helper: 'Mínimo de 6 caracteres',
                  ),
                  validator: (v) => (v ?? '').length < 6
                      ? 'A senha deve ter no mínimo 6 caracteres.'
                      : null,
                ),
              ],
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isEditing ? 'Salvar' : 'Cadastrar',
                busyLabel: 'Salvando...',
                busy: _saving,
                onPressed: _save,
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'Cancelar',
                onPressed: () => Navigator.of(context).pop(false),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
