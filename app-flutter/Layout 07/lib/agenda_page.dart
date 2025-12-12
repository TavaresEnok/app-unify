import 'package:flutter/material.dart';
import 'shared/theme/app_colors.dart';

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});

  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  final DateTime _now = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Agenda'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          _buildDayHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimelineItem(
                    time: '08:00',
                    child: const _TimeSlotCard(
                      title: 'Deslocamento',
                      subtitle: 'Base -> Cliente A',
                      color: AppColors.surface,
                      textColor: AppColors.textSecondary,
                      icon: Icons.directions_car,
                      isTravel: true,
                    ),
                  ),
                  _buildTimelineItem(
                    time: '09:00',
                    child: const _TimeSlotCard(
                      title: 'Instalação Fibra 300MB',
                      subtitle: 'Rua das Palmeiras, 45',
                      color: AppColors.primaryLight,
                      textColor: AppColors.primaryDark,
                      icon: Icons.router,
                      duration: '2h',
                      isJob: true,
                    ),
                  ),
                  _buildTimelineItem(
                    time: '11:00',
                    hasLine: true,
                    child: const SizedBox(height: 40), // Espaço livre
                  ),
                  _buildTimelineItem(
                    time: '13:00',
                    child: const _TimeSlotCard(
                      title: 'Almoço',
                      subtitle: '',
                      color: AppColors.surface,
                      textColor: AppColors.textSecondary,
                      icon: Icons.restaurant,
                      height: 60,
                    ),
                  ),
                  _buildTimelineItem(
                    time: '14:00',
                    child: const _TimeSlotCard(
                      title: 'Manutenção Externa',
                      subtitle: 'Av. Central, 1000',
                      color: AppColors.primaryLight,
                      textColor: AppColors.primaryDark,
                      icon: Icons.build,
                      duration: '1h 30m',
                      isJob: true,
                    ),
                  ),
                  _buildTimelineItem(
                    time: '16:00',
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.border, style: BorderStyle.values[1]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Horário Livre',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayHeader() {
    return Container(
      height: 80,
      color: AppColors.background,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 7,
        itemBuilder: (context, index) {
          final date = _now.add(Duration(days: index - 2));
          final isToday = index == 2;
          return Container(
            width: 60,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
            decoration: BoxDecoration(
              color: isToday ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isToday ? null : Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  ['DOM', 'SEG', 'TER', 'QUA', 'QUI', 'SEX', 'SAB'][date.weekday % 7],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.white : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${date.day}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isToday ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTimelineItem({required String time, required Widget child, bool hasLine = true}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 50,
            child: Text(
              time,
              style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
            ),
          ),
          Container(
            width: 2,
            color: AppColors.border,
            margin: const EdgeInsets.only(right: 16, bottom: 16),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  final String title, subtitle;
  final Color color, textColor;
  final IconData icon;
  final String? duration;
  final bool isJob;
  final bool isTravel;
  final double? height;

  const _TimeSlotCard({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.textColor,
    required this.icon,
    this.duration,
    this.isJob = false,
    this.isTravel = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isTravel ? Colors.white : color,
        borderRadius: BorderRadius.circular(12),
        border: isTravel 
          ? Border.all(color: AppColors.border, style: BorderStyle.solid) // Tracejado seria ideal, mas solid serve
          : (isJob ? const Border(left: BorderSide(color: AppColors.primary, width: 4)) : null),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 15),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(color: textColor.withOpacity(0.8), fontSize: 13),
                  ),
              ],
            ),
          ),
          if (duration != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                duration!,
                style: TextStyle(fontWeight: FontWeight.bold, color: textColor, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}
