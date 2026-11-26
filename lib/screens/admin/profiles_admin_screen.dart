import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/core_catalog_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/date_field.dart';
import '../profile/profile_screen.dart' show validateOptionalUrl;

class ProfilesAdminScreen extends StatefulWidget {
  const ProfilesAdminScreen({super.key});

  @override
  State<ProfilesAdminScreen> createState() => _ProfilesAdminScreenState();
}

class _ProfilesAdminScreenState extends State<ProfilesAdminScreen> {
  List<Profile> _profiles = [];
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
    final api = CoreCatalogApi.instance;
    try {
      final results = await Future.wait<List<Object>>([
        api.profiles(),
        api.users(),
      ]);
      if (!mounted) return;
      setState(() {
        _profiles = results[0].cast<Profile>();
        _users = results[1].cast<AppUser>();
      });
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.statusCode == 401
            ? e.message
            : 'Não foi possível carregar os dados. Verifique a API e o login.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<AppUser> get _usersWithoutProfile => _users
      .where((u) => !_profiles.any((p) => p.userId == u.id))
      .toList();

  Future<void> _openForm([Profile? profile]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfileFormScreen(
          profile: profile,
          availableUsers: _usersWithoutProfile,
        ),
      ),
    );
    if (saved == true && mounted) {
      showSnack(context, profile == null ? 'Perfil cadastrado.' : 'Perfil atualizado.');
      _load();
    }
  }

  Future<void> _remove(Profile profile) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir perfil',
      message: 'Excluir este perfil? As builds dele também serão apagadas.',
    );
    if (!ok || !mounted) return;
    setState(() => _error = '');
    try {
      await CoreCatalogApi.instance.deleteProfile(profile.id);
      if (!mounted) return;
      showSnack(context, 'Perfil excluído.');
      _load();
    } on ApiException {
      if (mounted) setState(() => _error = 'Não foi possível excluir o perfil.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Perfis', style: AppText.sectionTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Novo perfil'),
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
            if (_loading && _profiles.isEmpty)
              const EmptyState('Carregando perfis...', loading: true)
            else if (_profiles.isEmpty)
              const EmptyState('Nenhum perfil cadastrado.')
            else
              for (final p in _profiles)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: appCardDecoration(),
                  child: Row(
                    children: [
                      ProfileAvatar(name: p.fullName, url: p.avatarUrl),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.fullName, style: AppText.itemName),
                            const SizedBox(height: 2),
                            Text(
                              '${p.userName ?? ''} · ${p.userEmail ?? ''}',
                              style: AppText.secondary,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Nascimento: ${formatDateBr(p.birthDate)}',
                              style: AppText.secondary,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _openForm(p),
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.brand),
                      ),
                      IconButton(
                        tooltip: 'Excluir',
                        onPressed: () => _remove(p),
                        icon: const Icon(Icons.delete_outline,
                            color: AppColors.alertText),
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

class ProfileFormScreen extends StatefulWidget {
  const ProfileFormScreen({
    super.key,
    this.profile,
    required this.availableUsers,
  });

  final Profile? profile;
  final List<AppUser> availableUsers;

  @override
  State<ProfileFormScreen> createState() => _ProfileFormScreenState();
}

class _ProfileFormScreenState extends State<ProfileFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _fullName =
      TextEditingController(text: widget.profile?.fullName ?? '');
  late final _avatarUrl =
      TextEditingController(text: widget.profile?.avatarUrl ?? '');
  late String? _birthDate = widget.profile?.birthDateOnly;
  int? _userId;
  bool _saving = false;
  String _error = '';

  bool get _isEditing => widget.profile != null;

  @override
  void dispose() {
    _fullName.dispose();
    _avatarUrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = '');
    if (!_formKey.currentState!.validate()) return;
    if (!_isEditing && _userId == null) {
      setState(() => _error = 'Selecione um usuário.');
      return;
    }
    setState(() => _saving = true);
    final api = CoreCatalogApi.instance;
    try {
      if (_isEditing) {
        await api.updateProfile(
          widget.profile!.id,
          fullName: _fullName.text.trim(),
          birthDate: _birthDate,
          avatarUrl: _avatarUrl.text.trim(),
        );
      } else {
        await api.createProfile(
          userId: _userId!,
          fullName: _fullName.text.trim(),
          birthDate: _birthDate,
          avatarUrl: _avatarUrl.text.trim(),
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _userField() {
    final profile = widget.profile;
    if (profile != null) {
      return InputDecorator(
        decoration: appInputDecoration(label: 'Usuário').copyWith(enabled: false),
        child: Text('${profile.userName ?? ''} (${profile.userEmail ?? ''})'),
      );
    }
    if (widget.availableUsers.isEmpty) {
      return const AlertBanner(
        'Todos os usuários já têm perfil. Cadastre um novo usuário primeiro.',
      );
    }
    return InputDecorator(
      decoration: appInputDecoration(label: 'Usuário'),
      isEmpty: _userId == null,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _userId,
          isExpanded: true,
          isDense: true,
          hint: const Text('Selecione um usuário'),
          items: [
            for (final u in widget.availableUsers)
              DropdownMenuItem(
                value: u.id,
                child: Text('${u.name} (${u.email})',
                    overflow: TextOverflow.ellipsis),
              ),
          ],
          onChanged: (v) => setState(() => _userId = v),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        title: Text(_isEditing ? 'Editar perfil' : 'Novo perfil',
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
              _userField(),
              const SizedBox(height: 20),
              TextFormField(
                controller: _fullName,
                maxLength: 120,
                textCapitalization: TextCapitalization.words,
                decoration: appInputDecoration(
                    label: 'Nome completo', hint: 'Nome completo'),
                validator: (v) => (v ?? '').trim().length < 2
                    ? 'Informe o nome completo (mínimo 2 caracteres).'
                    : null,
              ),
              const SizedBox(height: 8),
              DateField(
                label: 'Data de nascimento',
                value: _birthDate,
                onChanged: (v) => setState(() => _birthDate = v),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _avatarUrl,
                keyboardType: TextInputType.url,
                autocorrect: false,
                maxLength: 500,
                decoration: appInputDecoration(
                    label: 'URL do avatar', hint: 'https://...'),
                validator: validateOptionalUrl,
              ),
              const SizedBox(height: 16),
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
