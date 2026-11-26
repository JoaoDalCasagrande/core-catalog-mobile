import 'package:flutter/material.dart';

import '../../models/models.dart';
import '../../services/api_client.dart';
import '../../services/core_catalog_api.dart';
import '../../theme/app_theme.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import 'build_detail_screen.dart';
import 'new_build_screen.dart';

class BuildsScreen extends StatefulWidget {
  const BuildsScreen({super.key});

  @override
  State<BuildsScreen> createState() => _BuildsScreenState();
}

class _BuildsScreenState extends State<BuildsScreen> {
  List<BuildListItem> _builds = [];
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
      final data = await CoreCatalogApi.instance.myBuilds();
      if (mounted) setState(() => _builds = data);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _error = e.statusCode == 401
            ? e.message
            : 'Não foi possível carregar suas builds.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openBuild(BuildListItem build) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => BuildDetailScreen(buildId: build.id)),
    );
    if (mounted) _load();
  }

  Future<void> _remove(BuildListItem build) async {
    final ok = await confirmDialog(
      context,
      title: 'Excluir build',
      message: 'Excluir a build "${build.name}"? Essa ação não pode ser desfeita.',
    );
    if (!ok || !mounted) return;
    setState(() => _error = '');
    try {
      await CoreCatalogApi.instance.deleteBuild(build.id);
      if (!mounted) return;
      setState(() => _builds = _builds.where((b) => b.id != build.id).toList());
      showSnack(context, 'Build excluída.');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _newBuild() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NewBuildScreen()),
    );
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Builds', style: AppText.sectionTitle),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _newBuild,
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nova build'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
          children: [
            const PageHeader(
              title: 'Builds',
              subtitle: 'Suas montagens e o orçamento de cada uma.',
            ),
            const SizedBox(height: 16),
            if (_error.isNotEmpty) ...[
              AlertBanner(_error),
              const SizedBox(height: 12),
            ],
            if (_loading && _builds.isEmpty)
              const EmptyState('Carregando builds...', loading: true)
            else if (_error.isEmpty && _builds.isEmpty)
              const EmptyState(
                  'Você ainda não tem builds. Crie a primeira para começar.')
            else
              for (final b in _builds)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Material(
                    color: AppColors.bgRaised,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: const BorderSide(color: AppColors.borderSubtle),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () => _openBuild(b),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.name,
                                    style: AppText.sectionTitle
                                        .copyWith(fontSize: 24),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Orçamento de ${formatMoney(b.maxBudgetCents)}',
                                    style: AppText.subtitle,
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Excluir build',
                              onPressed: () => _remove(b),
                              icon: const Icon(Icons.delete_outline,
                                  color: AppColors.alertText),
                            ),
                            const Icon(Icons.chevron_right,
                                color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
