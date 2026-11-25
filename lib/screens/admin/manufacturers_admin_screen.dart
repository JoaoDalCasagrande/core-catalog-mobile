import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/core_catalog_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';

/// Fabricantes: as marcas disponíveis ao cadastrar uma peça.
class ManufacturersAdminScreen extends StatefulWidget {
  const ManufacturersAdminScreen({super.key});

  @override
  State<ManufacturersAdminScreen> createState() =>
      _ManufacturersAdminScreenState();
}

class _ManufacturersAdminScreenState extends State<ManufacturersAdminScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  List<Manufacturer> _manufacturers = [];
  bool _loading = true;
  bool _saving = false;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await CoreCatalogApi.instance.manufacturers();
      if (mounted) setState(() => _manufacturers = data);
    } on ApiException {
      if (mounted) {
        setState(() => _error =
            'Não foi possível carregar os fabricantes. Verifique a API.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _error = '');
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      await CoreCatalogApi.instance.createManufacturer(name);
      if (!mounted) return;
      _name.clear();
      FocusScope.of(context).unfocus();
      showSnack(context, 'Fabricante $name cadastrado.');
      await _load();
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
        title: const Text('Fabricantes', style: AppText.sectionTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const PageHeader(
              title: 'Fabricantes',
              subtitle: 'As marcas disponíveis ao cadastrar uma peça.',
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty) ...[
              AlertBanner(_error),
              const SizedBox(height: 12),
            ],
            Container(
              padding: const EdgeInsets.all(16),
              decoration: appCardDecoration(),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Novo fabricante', style: AppText.sectionTitle),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _name,
                      maxLength: 60,
                      textCapitalization: TextCapitalization.words,
                      onFieldSubmitted: (_) => _save(),
                      decoration:
                          appInputDecoration(label: 'Nome', hint: 'Ex.: Intel'),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Informe o nome do fabricante.'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    PrimaryButton(
                      label: 'Cadastrar fabricante',
                      busyLabel: 'Cadastrando...',
                      busy: _saving,
                      onPressed: _save,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_loading && _manufacturers.isEmpty)
              const EmptyState('Carregando fabricantes...', loading: true)
            else if (_manufacturers.isEmpty)
              const EmptyState('Nenhum fabricante cadastrado.')
            else
              Container(
                decoration: appCardDecoration(),
                child: Column(
                  children: [
                    for (var i = 0; i < _manufacturers.length; i++) ...[
                      if (i > 0) const Divider(height: 1),
                      ListTile(
                        title: Text(_manufacturers[i].name,
                            style: AppText.label),
                        trailing: Text('ID ${_manufacturers[i].id}',
                            style: AppText.secondary),
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
