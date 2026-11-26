import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/core_catalog_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/budget_ruler.dart';
import '../../widgets/common.dart';
import '../profile/profile_screen.dart';
import 'build_detail_screen.dart';

class NewBuildScreen extends StatefulWidget {
  const NewBuildScreen({super.key});

  @override
  State<NewBuildScreen> createState() => _NewBuildScreenState();
}

class _NewBuildScreenState extends State<NewBuildScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _budget = TextEditingController(text: formatMoney(800000));

  Profile? _profile;
  bool _profileChecked = false;
  bool _saving = false;
  String _error = '';

  int get _budgetCents => parseCents(_budget.text);

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _budget.addListener(() => setState(() {}));
    _loadProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _profileChecked = false);
    try {
      final profile = await CoreCatalogApi.instance.myProfile();
      if (mounted) setState(() => _profile = profile);
    } on ApiException {
      if (mounted) setState(() => _error = 'Não foi possível carregar seu perfil.');
    } finally {
      if (mounted) setState(() => _profileChecked = true);
    }
  }

  Future<void> _createProfile() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileScreen(popOnSave: true),
      ),
    );
    if (mounted) _loadProfile();
  }

  Future<void> _submit() async {
    setState(() => _error = '');
    if (!_formKey.currentState!.validate()) return;
    if (_profile == null) {
      setState(() => _error = 'Crie seu perfil antes de montar uma build.');
      return;
    }
    if (_budgetCents <= 0) {
      setState(() => _error = 'Informe um orçamento maior que zero.');
      return;
    }

    setState(() => _saving = true);
    try {
      final created = await CoreCatalogApi.instance
          .createBuild(_name.text.trim(), _budgetCents);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => BuildDetailScreen(buildId: created.id),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileText = _profile != null
        ? _profile!.fullName
        : (_profileChecked ? 'Você ainda não tem perfil' : 'Carregando...');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Nova build', style: AppText.sectionTitle),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const PageHeader(
              title: 'Nova build',
              subtitle:
                  'Defina o orçamento. Cada peça adicionada é conferida contra esse limite.',
            ),
            const SizedBox(height: 20),
            if (_error.isNotEmpty) ...[
              AlertBanner(_error),
              const SizedBox(height: 16),
            ],
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: _name,
                    maxLength: 100,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: appInputDecoration(
                      label: 'Nome da build',
                      hint: 'Ex.: PC Gamer 2026',
                    ),
                    validator: (v) => (v ?? '').trim().isEmpty
                        ? 'Informe o nome da build.'
                        : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _budget,
                    keyboardType: TextInputType.number,
                    inputFormatters: [CentsInputFormatter()],
                    decoration: appInputDecoration(
                      label: 'Orçamento máximo',
                      helper:
                          'Peças que ultrapassem esse valor não serão adicionadas.',
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    key: ValueKey(profileText),
                    initialValue: profileText,
                    enabled: false,
                    decoration: appInputDecoration(label: 'Perfil'),
                  ),
                  if (_profileChecked && _profile == null)
                    TextButton.icon(
                      onPressed: _createProfile,
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                      label: const Text('Criar meu perfil'),
                    ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Criar build',
                    busyLabel: 'Criando...',
                    busy: _saving,
                    onPressed: _profile == null ? null : _submit,
                  ),
                  const SizedBox(height: 10),
                  SecondaryButton(
                    label: 'Cancelar',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _Preview(
              name: _name.text.trim().isEmpty ? 'Nova build' : _name.text.trim(),
              budgetCents: _budgetCents,
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.name, required this.budgetCents});

  final String name;
  final int budgetCents;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: appCardDecoration(color: AppColors.bgPage),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name, style: AppText.sectionTitle),
          const SizedBox(height: 12),
          Text(formatMoney(0), style: AppText.pageTitle),
          Text('de ${formatMoney(budgetCents)}', style: AppText.subtitle),
          const SizedBox(height: 16),
          BudgetRuler(
            segments: const [],
            maxBudgetCents: budgetCents,
            showLimit: false,
          ),
          const SizedBox(height: 8),
          const Text(
            'Nenhuma peça ainda. Depois de criar a build, adicione peças do catálogo e acompanhe o gasto e o consumo aqui.',
            style: AppText.subtitle,
          ),
        ],
      ),
    );
  }
}
