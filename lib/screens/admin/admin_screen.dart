import 'package:flutter/material.dart';

import '../../services/core_catalog_api.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common.dart';
import 'components_admin_screen.dart';
import 'manufacturers_admin_screen.dart';
import 'profiles_admin_screen.dart';
import 'users_admin_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int? _users;
  int? _profiles;
  int? _components;
  int? _manufacturers;

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final api = CoreCatalogApi.instance;
    Future<int?> count(Future<List<Object>> Function() load) async {
      try {
        return (await load()).length;
      } catch (_) {
        return null;
      }
    }

    final results = await Future.wait([
      count(api.users),
      count(api.profiles),
      count(api.components),
      count(api.manufacturers),
    ]);
    if (!mounted) return;
    setState(() {
      _users = results[0];
      _profiles = results[1];
      _components = results[2];
      _manufacturers = results[3];
    });
  }

  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) _loadCounts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        title: const Text('Painel', style: AppText.sectionTitle),
      ),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
          children: [
            const PageHeader(
              title: 'Painel',
              subtitle: 'Gerencie os dados que alimentam o catálogo e as builds.',
            ),
            const SizedBox(height: 20),
            _AdminTile(
              icon: Icons.group_outlined,
              title: 'Usuários',
              description: 'Cadastre, edite e exclua as contas de acesso.',
              count: _users,
              countLabel: 'usuários cadastrados',
              action: 'Gerenciar usuários',
              onTap: () => _open(const UsersAdminScreen()),
            ),
            _AdminTile(
              icon: Icons.badge_outlined,
              title: 'Perfis',
              description: 'Nome completo, nascimento e avatar de cada usuário.',
              count: _profiles,
              countLabel: 'perfis cadastrados',
              action: 'Gerenciar perfis',
              onTap: () => _open(const ProfilesAdminScreen()),
            ),
            _AdminTile(
              icon: Icons.memory_outlined,
              title: 'Peças',
              description:
                  'Cadastre as peças que aparecem no catálogo, com preço e consumo.',
              count: _components,
              countLabel: 'peças no catálogo',
              action: 'Gerenciar peças',
              onTap: () => _open(const ComponentsAdminScreen()),
            ),
            _AdminTile(
              icon: Icons.factory_outlined,
              title: 'Fabricantes',
              description: 'As marcas disponíveis ao cadastrar uma peça.',
              count: _manufacturers,
              countLabel: 'fabricantes',
              action: 'Gerenciar fabricantes',
              onTap: () => _open(const ManufacturersAdminScreen()),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.count,
    required this.countLabel,
    required this.action,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final int? count;
  final String countLabel;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: appCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: AppColors.brand),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.sectionTitle),
                    const SizedBox(height: 4),
                    Text(description, style: AppText.subtitle),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    count?.toString() ?? '—',
                    style: AppText.pageTitle.copyWith(fontSize: 32),
                  ),
                  SizedBox(
                    width: 84,
                    child: Text(
                      countLabel,
                      textAlign: TextAlign.end,
                      style: AppText.secondary.copyWith(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SecondaryButton(label: action, onPressed: onTap),
        ],
      ),
    );
  }
}
