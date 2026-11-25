import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/core_catalog_api.dart';
import '../../services/session.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../auth/login_screen.dart';
import '../auth/register_screen.dart';
import '../builds/new_build_screen.dart';

enum SortKey { priceAsc, priceDesc, wattsAsc, name }

const sortLabels = {
  SortKey.priceAsc: 'Menor preço',
  SortKey.priceDesc: 'Maior preço',
  SortKey.wattsAsc: 'Menor consumo',
  SortKey.name: 'Nome',
};

/// Ordem das categorias como no protótipo; categorias extras vão para o fim.
const categoryOrder = [
  'CPU',
  'GPU',
  'Placa-mãe',
  'RAM',
  'Armazenamento',
  'Fonte',
];

/// Catálogo de peças com filtros (categoria, fabricante, busca e ordenação)
/// e o botão "Adicionar" para colocar a peça em uma build.
///
/// Com [targetBuild], é aberto a partir de uma build ("Adicionar peça")
/// e adiciona direto nela, como o `/?buildId=` do web.
class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key, this.targetBuild, this.onOpenBuilds});

  final BuildListItem? targetBuild;
  final VoidCallback? onOpenBuilds;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  final _api = CoreCatalogApi.instance;
  final _searchController = TextEditingController();

  List<CatalogComponent> _components = [];
  bool _loading = true;
  String _error = '';

  String _category = '';
  final Set<String> _selectedManufacturers = {};
  String _search = '';
  SortKey _sort = SortKey.priceAsc;
  int? _addingId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });
    try {
      final data = await _api.components();
      if (!mounted) return;
      setState(() => _components = data);
    } on ApiException {
      if (!mounted) return;
      setState(() => _error =
          'Não foi possível carregar o catálogo. Verifique se a API está rodando.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Map<String, int> _countBy(String Function(CatalogComponent) key) {
    final counts = <String, int>{};
    for (final c in _components) {
      counts.update(key(c), (v) => v + 1, ifAbsent: () => 1);
    }
    return counts;
  }

  List<MapEntry<String, int>> get _categories {
    final entries = _countBy((c) => c.category).entries.toList();
    int rank(String name) {
      final i = categoryOrder.indexOf(name);
      return i == -1 ? 99 : i;
    }

    entries.sort((a, b) {
      final byRank = rank(a.key) - rank(b.key);
      return byRank != 0 ? byRank : a.key.compareTo(b.key);
    });
    return entries;
  }

  List<MapEntry<String, int>> get _manufacturers {
    final entries = _countBy((c) => c.manufacturerName).entries.toList();
    entries.sort((a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()));
    return entries;
  }

  List<CatalogComponent> get _visible {
    final term = _search.trim().toLowerCase();
    final filtered = _components.where((c) {
      return (_category.isEmpty || c.category == _category) &&
          (_selectedManufacturers.isEmpty ||
              _selectedManufacturers.contains(c.manufacturerName)) &&
          (term.isEmpty ||
              c.name.toLowerCase().contains(term) ||
              c.manufacturerName.toLowerCase().contains(term));
    }).toList();

    switch (_sort) {
      case SortKey.priceAsc:
        filtered.sort((a, b) => a.priceCents.compareTo(b.priceCents));
      case SortKey.priceDesc:
        filtered.sort((a, b) => b.priceCents.compareTo(a.priceCents));
      case SortKey.wattsAsc:
        filtered.sort((a, b) => a.powerWatts.compareTo(b.powerWatts));
      case SortKey.name:
        filtered.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
    return filtered;
  }

  // -------------------------------------------------------- adicionar

  /// Se já há build escolhida, adiciona direto. Senão, carrega as builds
  /// do usuário e mostra a lista para escolher (como no web).
  Future<void> _onAdd(CatalogComponent component) async {
    if (!await ensureLoggedIn(context)) return;
    if (!mounted) return;

    final target = widget.targetBuild;
    if (target != null) {
      await _addItem(target, component, 1);
      return;
    }

    List<BuildListItem> builds;
    try {
      builds = await _api.myBuilds();
    } on ApiException catch (e) {
      if (mounted) showSnack(context, e.message, error: true);
      return;
    }
    if (!mounted) return;

    final choice = await showModalBottomSheet<_BuildChoice>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: AppColors.bgRaised,
      builder: (_) => _BuildPickerSheet(component: component, builds: builds),
    );
    if (choice == null || !mounted) return;

    if (choice.createNew) {
      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const NewBuildScreen()),
      );
      return;
    }
    await _addItem(choice.build!, component, choice.quantity);
  }

  Future<void> _addItem(
      BuildListItem build, CatalogComponent component, int quantity) async {
    setState(() => _addingId = component.id);
    try {
      await _api.addBuildItem(build.id, component.id, quantity: quantity);
      if (!mounted) return;
      final qty = quantity > 1 ? '$quantity× ' : '';
      showSnack(context, '$qty${component.name} adicionada à build ${build.name}.');
    } on ApiException catch (e) {
      // Ex.: "Item ultrapassa o orçamento da build: ..."
      if (mounted) showSnack(context, e.message, error: true);
    } finally {
      if (mounted) setState(() => _addingId = null);
    }
  }

  // ------------------------------------------------------------ filtros

  Future<void> _openManufacturerFilter() async {
    final manufacturers = _manufacturers;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.bgRaised,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text('Fabricante', style: AppText.sectionTitle),
                    ),
                    TextButton(
                      onPressed: _selectedManufacturers.isEmpty
                          ? null
                          : () {
                              setState(_selectedManufacturers.clear);
                              setSheetState(() {});
                            },
                      child: const Text('Limpar'),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final m in manufacturers)
                      CheckboxListTile(
                        value: _selectedManufacturers.contains(m.key),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: Text(m.key),
                        secondary: Text('${m.value}', style: AppText.secondary),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedManufacturers.add(m.key);
                            } else {
                              _selectedManufacturers.remove(m.key);
                            }
                          });
                          setSheetState(() {});
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // --------------------------------------------------------------- UI

  @override
  Widget build(BuildContext context) {
    final target = widget.targetBuild;
    final visible = _visible;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          target == null ? 'Core Catalog' : 'Adicionar à build',
          style: AppText.sectionTitle,
        ),
        actions: [
          if (target == null) _AccountMenu(onOpenBuilds: widget.onOpenBuilds),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  PageHeader(
                    title: 'Catálogo de peças',
                    subtitle: target == null
                        ? 'Compare preço e consumo antes de montar sua build.'
                        : 'Toque em "Adicionar" para colocar a peça em ${target.name} '
                            '(orçamento de ${formatMoney(target.maxBudgetCents)}).',
                  ),
                  const SizedBox(height: 16),
                  if (_error.isNotEmpty) ...[
                    AlertBanner(_error),
                    const SizedBox(height: 12),
                  ],
                  _buildToolbar(),
                  const SizedBox(height: 12),
                ]),
              ),
            ),
            SliverToBoxAdapter(child: _buildCategoryChips()),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            if (_loading && _components.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState('Carregando peças...', loading: true),
              )
            else if (visible.isEmpty)
              const SliverToBoxAdapter(
                child: EmptyState('Nenhuma peça encontrada.'),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ComponentCard(
                        component: visible[i],
                        adding: _addingId == visible[i].id,
                        onAdd: () => _onAdd(visible[i]),
                      ),
                    ),
                    childCount: visible.length,
                  ),
                ),
              ),
            if (!_loading)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                  child: Text(
                    'Mostrando ${visible.length} de ${_components.length} peças',
                    textAlign: TextAlign.center,
                    style: AppText.secondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    final filterCount = _selectedManufacturers.length;
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _search = v),
            textInputAction: TextInputAction.search,
            decoration: appInputDecoration(
              hint: 'Buscar peça ou fabricante',
              suffixIcon: _search.isEmpty
                  ? const Icon(Icons.search)
                  : IconButton(
                      tooltip: 'Limpar busca',
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
                      },
                    ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Badge(
          isLabelVisible: filterCount > 0,
          label: Text('$filterCount'),
          backgroundColor: AppColors.brand,
          child: IconButton.outlined(
            tooltip: 'Filtrar por fabricante',
            onPressed: _components.isEmpty ? null : _openManufacturerFilter,
            icon: const Icon(Icons.tune),
          ),
        ),
        PopupMenuButton<SortKey>(
          tooltip: 'Ordenar por',
          initialValue: _sort,
          onSelected: (value) => setState(() => _sort = value),
          itemBuilder: (context) => [
            for (final entry in sortLabels.entries)
              CheckedPopupMenuItem(
                value: entry.key,
                checked: entry.key == _sort,
                child: Text(entry.value),
              ),
          ],
          icon: const Icon(Icons.sort),
        ),
      ],
    );
  }

  Widget _buildCategoryChips() {
    final chips = <Widget>[
      _categoryChip('Todas', _components.length, ''),
      for (final c in _categories) _categoryChip(c.key, c.value, c.key),
    ];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  Widget _categoryChip(String label, int count, String value) {
    final selected = _category == value;
    return ChoiceChip(
      label: Text('$label  $count'),
      selected: selected,
      showCheckmark: false,
      selectedColor: AppColors.bgBrandTint,
      backgroundColor: AppColors.bgRaised,
      side: BorderSide(
        color: selected ? AppColors.brand : AppColors.borderSubtle,
      ),
      labelStyle: TextStyle(
        color: AppColors.textPrimary,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
      onSelected: (_) => setState(() => _category = value),
    );
  }
}

/// Uma linha do catálogo: nome, fabricante, categoria, consumo e preço.
class _ComponentCard extends StatelessWidget {
  const _ComponentCard({
    required this.component,
    required this.onAdd,
    this.adding = false,
  });

  final CatalogComponent component;
  final VoidCallback onAdd;
  final bool adding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: appCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(component.name, style: AppText.itemName),
                    const SizedBox(height: 2),
                    Text(component.manufacturerName, style: AppText.secondary),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CategoryTag(component.category),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.bolt_outlined,
                  size: 18, color: AppColors.textSecondary),
              Text('${component.powerWatts} W', style: AppText.secondary),
              const Spacer(),
              Text(formatMoney(component.priceCents), style: AppText.price),
              const SizedBox(width: 12),
              SizedBox(
                height: 36,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4)),
                  ),
                  onPressed: adding ? null : onAdd,
                  child: adding
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Adicionar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Resultado da escolha de build no "Adicionar".
class _BuildChoice {
  final BuildListItem? build;
  final int quantity;
  final bool createNew;

  const _BuildChoice.existing(BuildListItem this.build, this.quantity)
      : createNew = false;

  const _BuildChoice.createNew()
      : build = null,
        quantity = 1,
        createNew = true;
}

/// "Escolha a build para adicionar X" (+ quantidade, que a API aceita).
class _BuildPickerSheet extends StatefulWidget {
  const _BuildPickerSheet({required this.component, required this.builds});

  final CatalogComponent component;
  final List<BuildListItem> builds;

  @override
  State<_BuildPickerSheet> createState() => _BuildPickerSheetState();
}

class _BuildPickerSheetState extends State<_BuildPickerSheet> {
  int _quantity = 1;

  @override
  Widget build(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.75;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Adicionar à build', style: AppText.sectionTitle),
              const SizedBox(height: 6),
              Text.rich(
                TextSpan(
                  style: AppText.subtitle,
                  children: [
                    const TextSpan(text: 'Escolha a build para adicionar '),
                    TextSpan(
                      text: widget.component.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextSpan(
                        text: ' (${formatMoney(widget.component.priceCents)}).'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (widget.builds.isEmpty) ...[
                const Text(
                  'Você ainda não tem builds.',
                  style: AppText.subtitle,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Criar build',
                  icon: Icons.add,
                  onPressed: () => Navigator.of(context)
                      .pop(const _BuildChoice.createNew()),
                ),
              ] else ...[
                Row(
                  children: [
                    const Expanded(
                        child: Text('Quantidade', style: AppText.label)),
                    IconButton.outlined(
                      tooltip: 'Diminuir',
                      onPressed: _quantity > 1
                          ? () => setState(() => _quantity--)
                          : null,
                      icon: const Icon(Icons.remove),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        '$_quantity',
                        textAlign: TextAlign.center,
                        style: AppText.itemName,
                      ),
                    ),
                    IconButton.outlined(
                      tooltip: 'Aumentar',
                      onPressed: _quantity < 20
                          ? () => setState(() => _quantity++)
                          : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      for (final b in widget.builds)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.build_circle_outlined,
                              color: AppColors.brand),
                          title: Text(b.name, style: AppText.itemName),
                          subtitle: Text(
                              'Orçamento de ${formatMoney(b.maxBudgetCents)}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () => Navigator.of(context)
                              .pop(_BuildChoice.existing(b, _quantity)),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                SecondaryButton(
                  label: 'Nova build',
                  icon: Icons.add,
                  onPressed: () => Navigator.of(context)
                      .pop(const _BuildChoice.createNew()),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Menu da conta no topo do catálogo: Entrar / Criar conta, ou Builds / Sair.
class _AccountMenu extends StatelessWidget {
  const _AccountMenu({this.onOpenBuilds});

  final VoidCallback? onOpenBuilds;

  @override
  Widget build(BuildContext context) {
    final session = Session.instance;
    if (!session.isAuthenticated) {
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => ensureLoggedIn(context),
              child: const Text('Entrar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4)),
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen()),
              ),
              child: const Text('Criar conta'),
            ),
          ],
        ),
      );
    }

    final user = session.user;
    return PopupMenuButton<String>(
      tooltip: 'Conta',
      icon: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.bgBrandTint,
        child: Text(
          initialsOf(user?.name.isNotEmpty == true ? user!.name : '?'),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.brand,
          ),
        ),
      ),
      onSelected: (value) {
        if (value == 'builds') onOpenBuilds?.call();
        if (value == 'logout') {
          Session.instance.signOut();
          showSnack(context, 'Você saiu da sua conta.');
        }
      },
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(user?.name ?? '', style: AppText.label),
              Text(user?.email ?? '', style: AppText.secondary),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'builds', child: Text('Minhas builds')),
        const PopupMenuItem(value: 'logout', child: Text('Sair')),
      ],
    );
  }
}
