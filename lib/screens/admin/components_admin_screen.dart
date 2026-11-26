import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/core_catalog_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../catalog/catalog_screen.dart' show categoryOrder;
import 'manufacturers_admin_screen.dart';

/// Peças: lista do catálogo e cadastro de novas peças (POST /components).
class ComponentsAdminScreen extends StatefulWidget {
  const ComponentsAdminScreen({super.key});

  @override
  State<ComponentsAdminScreen> createState() => _ComponentsAdminScreenState();
}

class _ComponentsAdminScreenState extends State<ComponentsAdminScreen> {
  List<CatalogComponent> _components = [];
  List<Manufacturer> _manufacturers = [];
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
        api.components(),
        api.manufacturers(),
      ]);
      if (!mounted) return;
      setState(() {
        _components = results[0].cast<CatalogComponent>();
        _manufacturers = results[1].cast<Manufacturer>();
      });
    } on ApiException {
      if (mounted) {
        setState(() =>
            _error = 'Não foi possível carregar as peças. Verifique a API.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openForm([CatalogComponent? component]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ComponentFormScreen(
          manufacturers: _manufacturers,
          component: component,
        ),
      ),
    );
    if (mounted) {
      if (saved == true) {
        showSnack(
          context,
          component == null ? 'Peça cadastrada.' : 'Peça atualizada.',
        );
      }
      _load();
    }
  }

  Future<void> _remove(CatalogComponent component) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir peça',
      message: 'Excluir a peça "${component.name}"?',
    );
    if (!ok || !mounted) return;
    setState(() => _error = '');
    try {
      await CoreCatalogApi.instance.deleteComponent(component.id);
      if (!mounted) return;
      showSnack(context, 'Peça excluída.');
      await _load();
    } on ApiException catch (e) {
      // Ex.: 409 quando a peça já está em alguma build
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Peças', style: AppText.sectionTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : () => _openForm(),
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova peça'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            const PageHeader(
              title: 'Peças',
              subtitle:
                  'Cadastre as peças que aparecem no catálogo, com preço e consumo.',
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty) ...[
              AlertBanner(_error),
              const SizedBox(height: 12),
            ],
            if (_loading && _components.isEmpty)
              const EmptyState('Carregando peças...', loading: true)
            else if (_components.isEmpty)
              const EmptyState('Nenhuma peça cadastrada.')
            else ...[
              for (final c in _components)
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: appCardDecoration(),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(c.name, style: AppText.itemName),
                            const SizedBox(height: 2),
                            Text(c.manufacturerName, style: AppText.secondary),
                            const SizedBox(height: 8),
                            CategoryTag(c.category),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(formatMoney(c.priceCents), style: AppText.price),
                          const SizedBox(height: 4),
                          Text('${c.powerWatts} W', style: AppText.secondary),
                          const SizedBox(height: 4),
                          RowActions(
                            onEdit: () => _openForm(c),
                            onDelete: () => _remove(c),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Mostrando ${_components.length} peças',
                  textAlign: TextAlign.center,
                  style: AppText.secondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Formulário "Nova peça" ou, quando recebe [component], "Editar peça".
class ComponentFormScreen extends StatefulWidget {
  const ComponentFormScreen({
    super.key,
    required this.manufacturers,
    this.component,
  });

  final List<Manufacturer> manufacturers;
  final CatalogComponent? component;

  @override
  State<ComponentFormScreen> createState() => _ComponentFormScreenState();
}

class _ComponentFormScreenState extends State<ComponentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.component?.name);
  late final _category =
      TextEditingController(text: widget.component?.category);
  late final _price =
      TextEditingController(text: formatMoney(widget.component?.priceCents ?? 0));
  late final _watts = TextEditingController(
      text: widget.component == null ? '' : '${widget.component!.powerWatts}');
  late List<Manufacturer> _manufacturers = widget.manufacturers;
  late int? _manufacturerId = widget.component?.manufacturerId;
  bool _saving = false;
  String _error = '';

  bool get _isEditing => widget.component != null;

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _price.dispose();
    _watts.dispose();
    super.dispose();
  }

  Future<void> _addManufacturer() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const ManufacturersAdminScreen()),
    );
    try {
      final list = await CoreCatalogApi.instance.manufacturers();
      if (mounted) setState(() => _manufacturers = list);
    } on ApiException {
      // mantém a lista atual
    }
  }

  Future<void> _save() async {
    setState(() => _error = '');
    if (!_formKey.currentState!.validate()) return;
    final priceCents = parseCents(_price.text);
    if (priceCents <= 0) {
      setState(() => _error = 'Informe um preço maior que zero.');
      return;
    }
    if (_manufacturerId == null) {
      setState(() => _error = 'Selecione um fabricante.');
      return;
    }

    setState(() => _saving = true);
    try {
      final api = CoreCatalogApi.instance;
      if (_isEditing) {
        await api.updateComponent(
          widget.component!.id,
          name: _name.text.trim(),
          category: _category.text.trim(),
          priceCents: priceCents,
          powerWatts: int.parse(_watts.text.trim()),
          manufacturerId: _manufacturerId!,
        );
      } else {
        await api.createComponent(
          name: _name.text.trim(),
          category: _category.text.trim(),
          priceCents: priceCents,
          powerWatts: int.parse(_watts.text.trim()),
          manufacturerId: _manufacturerId!,
        );
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
        title: Text(_isEditing ? 'Editar peça' : 'Nova peça',
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
                maxLength: 120,
                decoration: appInputDecoration(
                    label: 'Nome', hint: 'Ex.: Ryzen 7 7800X3D'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Informe o nome da peça.' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _category,
                maxLength: 40,
                decoration: appInputDecoration(
                    label: 'Categoria', hint: 'Ex.: CPU, GPU, RAM'),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Informe a categoria.' : null,
              ),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final c in categoryOrder)
                    ActionChip(
                      label: Text(c),
                      backgroundColor: AppColors.bgRaised,
                      side: const BorderSide(color: AppColors.borderSubtle),
                      onPressed: () => setState(() => _category.text = c),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              if (_manufacturers.isEmpty) ...[
                const AlertBanner(
                    'Nenhum fabricante cadastrado. Cadastre um fabricante antes da peça.'),
                const SizedBox(height: 8),
                SecondaryButton(
                  label: 'Cadastrar fabricante',
                  icon: Icons.factory_outlined,
                  onPressed: _addManufacturer,
                ),
              ] else
                InputDecorator(
                  decoration: appInputDecoration(label: 'Fabricante'),
                  isEmpty: _manufacturerId == null,
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: _manufacturerId,
                      isExpanded: true,
                      isDense: true,
                      hint: const Text('Selecione um fabricante'),
                      items: [
                        for (final m in _manufacturers)
                          DropdownMenuItem(value: m.id, child: Text(m.name)),
                      ],
                      onChanged: (v) => setState(() => _manufacturerId = v),
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [CentsInputFormatter()],
                decoration: appInputDecoration(label: 'Preço'),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _watts,
                keyboardType: TextInputType.number,
                decoration: appInputDecoration(
                  label: 'Consumo (W)',
                  hint: '0',
                  helper: 'Consumo máximo da peça em watts',
                ),
                validator: (v) {
                  final value = int.tryParse((v ?? '').trim());
                  if (value == null || value < 0) {
                    return 'Informe o consumo em watts (0 ou mais).';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isEditing ? 'Salvar' : 'Cadastrar peça',
                busyLabel: _isEditing ? 'Salvando...' : 'Cadastrando...',
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
