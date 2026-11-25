import 'package:flutter/material.dart';

import '../services/session.dart';
import '../theme/app_theme.dart';
import 'admin/admin_screen.dart';
import 'auth/login_screen.dart';
import 'auth/register_screen.dart';
import 'builds/builds_screen.dart';
import 'catalog/catalog_screen.dart';
import 'profile/profile_screen.dart';

/// Navegação principal: Catálogo, Builds, Perfil e Admin
/// (as mesmas áreas do cabeçalho do web).
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  static const _destinations = [
    NavigationDestination(
      icon: Icon(Icons.memory_outlined),
      selectedIcon: Icon(Icons.memory),
      label: 'Catálogo',
    ),
    NavigationDestination(
      icon: Icon(Icons.build_circle_outlined),
      selectedIcon: Icon(Icons.build_circle),
      label: 'Builds',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Perfil',
    ),
    NavigationDestination(
      icon: Icon(Icons.admin_panel_settings_outlined),
      selectedIcon: Icon(Icons.admin_panel_settings),
      label: 'Admin',
    ),
  ];

  Widget _page(Session session) {
    switch (_index) {
      case 1:
        return session.isAuthenticated
            ? BuildsScreen(key: ValueKey('builds-${session.token}'))
            : const LoginRequiredView(
                title: 'Builds',
                message: 'Entre na sua conta para ver e montar suas builds.',
              );
      case 2:
        return session.isAuthenticated
            ? ProfileScreen(key: ValueKey('profile-${session.token}'))
            : const LoginRequiredView(
                title: 'Meu perfil',
                message:
                    'Entre na sua conta para criar ou editar o seu perfil.',
              );
      case 3:
        return session.isAuthenticated
            ? AdminScreen(key: ValueKey('admin-${session.token}'))
            : const LoginRequiredView(
                title: 'Painel',
                message:
                    'Entre na sua conta para gerenciar usuários, perfis, peças e fabricantes.',
              );
      default:
        return CatalogScreen(onOpenBuilds: () => setState(() => _index = 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Session.instance,
      builder: (context, _) => Scaffold(
        body: _page(Session.instance),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          backgroundColor: AppColors.bgRaised,
          indicatorColor: AppColors.bgBrandTint,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: _destinations,
        ),
      ),
    );
  }
}

/// Mostrado nas abas que exigem login (no web, a página redireciona para /login).
class LoginRequiredView extends StatelessWidget {
  const LoginRequiredView({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgSurface,
        surfaceTintColor: Colors.transparent,
        title: Text(title, style: AppText.sectionTitle),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline,
                    size: 48, color: AppColors.brand3),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppText.subtitle,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () => ensureLoggedIn(context),
                  child: const Text('Entrar'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('Criar conta'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
