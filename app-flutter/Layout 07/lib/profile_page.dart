import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'shared/theme/app_colors.dart';
import 'services/auth_service.dart';
import 'suporte.dart'; // Para navegação ao suporte
import 'models/usuario.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final user = authService.usuario;

    if (user == null) return const SizedBox();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          const SliverAppBar(
            backgroundColor: AppColors.background,
            title: Text('Meu Perfil'),
            centerTitle: true,
            pinned: true,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _buildProfileHeader(context, user),
                  const SizedBox(height: 24),
                  _buildStatsRow(),
                  const SizedBox(height: 32),
                  _buildMenuSection(context),
                  const SizedBox(height: 32),
                  _buildLogoutButton(context, authService),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, Usuario user) {
    return Column(
      children: [
        Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 2),
              ),
              child: const CircleAvatar(
                radius: 50,
                backgroundColor: AppColors.surface,
                backgroundImage: NetworkImage('https://i.pravatar.cc/300'), // Placeholder image
                // child: Icon(Icons.person, size: 50, color: AppColors.textSecondary),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, size: 16, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.nome,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.verified, color: AppColors.primary, size: 20),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'Técnico Verificado',
            style: TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildStatItem('4.9', 'Avaliação', Icons.star, AppColors.accent),
        _ContainerDivider(),
        _buildStatItem('128', 'Serviços', Icons.work_outline, AppColors.textPrimary),
        _ContainerDivider(),
        _buildStatItem('2 Anos', 'Experiência', Icons.history, AppColors.textPrimary),
      ],
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMenuSection(BuildContext context) {
    return Column(
      children: [
        _buildMenuItem(
          icon: Icons.directions_car_outlined,
          title: 'Dados do Veículo',
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.map_outlined,
          title: 'Raio de Atuação',
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.account_balance_outlined,
          title: 'Dados Bancários',
          onTap: () {},
        ),
        const Divider(height: 32),
        _buildMenuItem(
          icon: Icons.notifications_outlined,
          title: 'Notificações',
          onTap: () {},
        ),
        _buildMenuItem(
          icon: Icons.headset_mic_outlined,
          title: 'Suporte do App',
          onTap: () {
            Navigator.push(
              context, 
              MaterialPageRoute(builder: (context) => const SuportePage(
                cpfCnpj: '', // Preencher com dados reais se necessário ou pegar do provider
                senha: '',
                status: '',
                clientName: '',
              ))
            );
          },
        ),
        _buildMenuItem(
          icon: Icons.settings_outlined,
          title: 'Configurações',
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildMenuItem({required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: AppColors.textPrimary, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
          color: AppColors.textPrimary,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textSecondary),
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildLogoutButton(BuildContext context, AuthService authService) {
    return TextButton.icon(
      onPressed: () => authService.logout(),
      icon: const Icon(Icons.logout, color: AppColors.error),
      label: const Text(
        'Sair da Conta',
        style: TextStyle(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        backgroundColor: AppColors.error.withOpacity(0.05),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _ContainerDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 40,
      width: 1,
      color: AppColors.divider,
    );
  }
}
