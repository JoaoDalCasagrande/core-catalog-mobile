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
  Manufacturer? _editing;
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

  void _edit(Manufacturer manufacturer) {
    setState(() {
      _error = '';
      _editing = manufacturer;
      _name.text = manufacturer.name;
    });
  }

  void _cancelEdit() {
    FocusScope.of(context).unfocus();
    setState(() {
      _editing = null;
      _name.clear();
    });
  }

  Future<void> _remove(Manufacturer manufacturer) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir fabricante',
      message: 'Excluir o fabricante "${manufacturer.name}"?',
    );
    if (!ok || !mounted) return;
    setState(() => _error = '');
    try {
      await CoreCatalogApi.instance.deleteManufacturer(manufacturer.id);
      if (!mounted) return;
      if (_editing?.id == manufacturer.id) _cancelEdit();
      showSnack(context, 'Fabricante excluído.');
      await _load();
    } on ApiException catch (e) {
      // Ex.: 409 quando ainda existem peças desse fabricante
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _save() async {
    setState(() => _error = '');
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final name = _name.text.trim();
      final editing = _editing;
      if (editing != null) {
        await CoreCatalogApi.instance.updateManufacturer(editing.id, name);
      } else {
        await CoreCatalogApi.instance.createManufacturer(name);
      }
      if (!mounted) return;
      _name.clear();
      FocusScope.of(context).unfocus();
      setState(() => _editing = null);
      showSnack(
        context,
        editing != null
            ? 'Fabricante $name atualizado.'
            : 'Fabricante $name cadastrado.',
      );
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
                    Text(_editing != null ? 'Editar fabricante' : 'Novo fabricante',
                        style: AppText.sectionTitle),
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
                      label: _editing != null ? 'Salvar' : 'Cadastrar fabricante',
                      busyLabel:
                          _editing != null ? 'Salvando...' : 'Cadastrando...',
                      busy: _saving,
                      onPressed: _save,
                    ),
                    if (_editing != null) ...[
                      const SizedBox(height: 10),
                      SecondaryButton(
                        label: 'Cancelar',
                        onPressed: _cancelEdit,
                      ),
                    ],
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
                        subtitle: Text('ID ${_manufacturers[i].id}',
                            style: AppText.secondary),
                        trailing: RowActions(
                          onEdit: () => _edit(_manufacturers[i]),
                          onDelete: () => _remove(_manufacturers[i]),
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
