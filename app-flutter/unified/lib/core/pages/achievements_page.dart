// Achievements Page
// Displays all achievements with unlock status

import 'package:flutter/material.dart';
import '../theme/layout_tokens.dart';
import '../models/achievement.dart';
import '../services/achievement_service.dart';
import '../vibe/vibe_page_parts.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  final AchievementService _service = AchievementService();
  List<Achievement> _achievements = [];
  int _unlockedCount = 0;
  bool _loading = true;
  ColorScheme get _colors => Theme.of(context).colorScheme;
  Color get _text => _colors.onSurface;
  Color get _muted => _colors.onSurfaceVariant;

  @override
  void initState() {
    super.initState();
    _loadAchievements();
  }

  Future<void> _loadAchievements() async {
    setState(() => _loading = true);
    final achievements = await _service.getAllAchievements();
    final count = await _service.getUnlockedCount();
    if (!mounted) return;
    setState(() {
      _achievements = achievements;
      _unlockedCount = count;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return VibeHeaderPage(
      title: 'Conquistas',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                _buildAchievementsList(),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    final progress = _achievements.isNotEmpty
        ? (_unlockedCount / _achievements.length * 100).round()
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _colors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: _colors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events,
                  color:
                      LayoutTokens.readable(_colors.primary, _colors.surface),
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$_unlockedCount de ${_achievements.length}',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: LayoutTokens.readable(
                            _colors.primary, _colors.surface),
                      ),
                    ),
                    Text(
                      'Conquistas desbloqueadas',
                      style: TextStyle(
                        fontSize: 13,
                        color: _muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress / 100,
              minHeight: 8,
              backgroundColor: _colors.outlineVariant,
              valueColor: AlwaysStoppedAnimation(_colors.primary),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$progress% concluído',
            style: TextStyle(
              fontSize: 12,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsList() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final singleColumn = constraints.maxWidth < 260 ||
            MediaQuery.textScalerOf(context).scale(1) > 1.5;
        final width = singleColumn
            ? constraints.maxWidth
            : (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _achievements
              .map((achievement) => SizedBox(
                    width: width,
                    child: _buildAchievementCard(achievement),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildAchievementCard(Achievement achievement) {
    final isUnlocked = achievement.isUnlocked;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _colors.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isUnlocked
                  ? achievement.color.withValues(alpha: 0.2)
                  : _colors.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(
              achievement.icon,
              color: isUnlocked
                  ? LayoutTokens.readable(achievement.color, _colors.surface)
                  : _muted,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isUnlocked ? _text : _muted,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: TextStyle(
              fontSize: 12,
              color: isUnlocked ? _muted : _muted,
            ),
          ),
          if (isUnlocked && achievement.unlockedAt != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color:
                      LayoutTokens.readable(achievement.color, _colors.surface),
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(achievement.unlockedAt!),
                  style: TextStyle(
                    fontSize: 11,
                    color: LayoutTokens.readable(
                        achievement.color, _colors.surface),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    if (diff.inDays < 7) return '${diff.inDays}d atrás';
    return '${date.day}/${date.month}/${date.year}';
  }
}
