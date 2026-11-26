import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/core_catalog_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/budget_ruler.dart';
import '../../widgets/common.dart';
import '../catalog/catalog_screen.dart';

/// Resumo da build (GET /builds/:id/summary): gasto x orçamento, consumo,
/// régua por categoria e a tabela de peças.
class BuildDetailScreen extends StatefulWidget {
  const BuildDetailScreen({super.key, required this.buildId});

  final int buildId;

  @override
  State<BuildDetailScreen> createState() => _BuildDetailScreenState();
}

class _BuildDetailScreenState extends State<BuildDetailScreen> {
  BuildSummary? _summary;
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
      final data = await CoreCatalogApi.instance.buildSummary(widget.buildId);
      if (mounted) setState(() => _summary = data);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.isNotFound) {
          _error = 'Build não encontrada.';
        } else if (e.statusCode == 401) {
          _error = e.message;
        } else {
          _error = 'Não foi possível carregar a build. Verifique a API.';
        }
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addPart() async {
    final summary = _summary;
    if (summary == null) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CatalogScreen(
          targetBuild: BuildListItem(
            id: widget.buildId,
            name: summary.name,
            maxBudgetCents: summary.maxBudgetCents,
          ),
        ),
      ),
    );
    if (mounted) _load();
  }

  Future<void> _remove() async {
    final summary = _summary;
    if (summary == null) return;
    final ok = await confirmDialog(
      context,
      title: 'Excluir build',
      message: 'Excluir a build "${summary.name}"? Essa ação não pode ser desfeita.',
    );
    if (!ok || !mounted) return;
    setState(() => _error = '');
    try {
      await CoreCatalogApi.instance.deleteBuild(widget.buildId);
      if (!mounted) return;
      showSnack(context, 'Build excluída.');
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        title: Text(summary?.name ?? 'Build', style: AppText.sectionTitle),
        actions: [
          if (summary != null)
            IconButton(
              tooltip: 'Excluir build',
              onPressed: _remove,
              icon: const Icon(Icons.delete_outline, color: AppColors.alertText),
            ),
          IconButton(
            tooltip: 'Atualizar',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: summary == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _addPart,
              backgroundColor: AppColors.brand,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar peça'),
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
            if (_loading && summary == null && _error.isEmpty)
              const EmptyState('Carregando build...', loading: true),
            if (summary != null) ..._content(summary),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(BuildSummary s) {
    final remaining = s.remainingCents;
    return [
      PageHeader(title: s.name, subtitle: 'Build de ${s.owner}'),
      const SizedBox(height: 16),
      if (s.overBudget) ...[
        AlertBanner(
          'Esta build está acima do orçamento em '
          '${formatMoney(s.totalCents - s.maxBudgetCents)}. '
          'Troque uma peça ou aumente o orçamento.',
        ),
        const SizedBox(height: 12),
      ],
      // Card do gasto + régua
      Container(
        padding: const EdgeInsets.all(16),
        decoration: appCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formatMoney(s.totalCents),
              style: AppText.pageTitle.copyWith(fontSize: 34),
            ),
            Text('de ${formatMoney(s.maxBudgetCents)} de orçamento',
                style: AppText.subtitle),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    remaining >= 0
                        ? 'Cabem mais ${formatMoney(remaining)}'
                        : 'Passou ${formatMoney(-remaining)}',
                    style: AppText.label.copyWith(
                      color: s.overBudget
                          ? AppColors.alertText
                          : AppColors.textPrimary,
                    ),
                  ),
                ),
                const Icon(Icons.bolt_outlined,
                    size: 18, color: AppColors.textSecondary),
                Text('${s.totalWatts} W de consumo', style: AppText.secondary),
              ],
            ),
            const SizedBox(height: 20),
            BudgetRuler(
              maxBudgetCents: s.maxBudgetCents,
              segments: [
                for (var i = 0; i < s.items.length; i++)
                  RulerSegment(
                    s.items[i].subtotalCents,
                    AppColors.forCategory(s.items[i].category, i),
                  ),
              ],
            ),
            if (s.items.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  for (var i = 0; i < s.items.length; i++)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: AppColors.forCategory(
                                s.items[i].category, i),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(s.items[i].category,
                            style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(formatMoney(s.items[i].unitPriceCents),
                            style: AppText.secondary),
                      ],
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Text('Peças', style: AppText.sectionTitle),
      const SizedBox(height: 10),
      if (s.items.isEmpty)
        Container(
          decoration: appCardDecoration(),
          child: const EmptyState(
            'Nenhuma peça ainda. Adicione peças do catálogo e acompanhe o gasto e o consumo aqui.',
          ),
        )
      else ...[
        for (final item in s.items)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _ItemCard(item: item),
          ),
        _TotalCard(summary: s),
      ],
    ];
  }
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.item});

  final BuildSummaryItem item;

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
                    Text(item.name, style: AppText.itemName),
                    const SizedBox(height: 2),
                    Text(item.manufacturer, style: AppText.secondary),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CategoryTag(item.category),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _Metric(label: 'Qtd.', value: '${item.quantity}'),
              _Metric(label: 'Consumo', value: '${item.powerWatts} W'),
              _Metric(
                  label: 'Unitário', value: formatMoney(item.unitPriceCents)),
              _Metric(
                label: 'Subtotal',
                value: formatMoney(item.subtotalCents),
                strong: true,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.summary});

  final BuildSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: appCardDecoration(color: AppColors.bgBrandTint),
      child: Row(
        children: [
          const Expanded(child: Text('Total', style: AppText.itemName)),
          _Metric(label: 'Qtd.', value: '${summary.totalQuantity}'),
          _Metric(label: 'Consumo', value: '${summary.totalWatts} W'),
          _Metric(
            label: 'Subtotal',
            value: formatMoney(summary.totalCents),
            strong: true,
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(label, style: AppText.secondary.copyWith(fontSize: 12)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: strong
                  ? AppText.price.copyWith(fontSize: 14)
                  : const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }
}
