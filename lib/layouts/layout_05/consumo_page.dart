import 'package:flutter/material.dart';
import 'theme.dart';

class ConsumoPage extends StatelessWidget {
  const ConsumoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: Text('Consumo', style: Layout05Theme.heading2),
        backgroundColor: Layout05Theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Layout05Theme.textDark),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: Layout05Theme.cardDecoration,
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    width: 200,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: 0.7,
                          strokeWidth: 12,
                          backgroundColor: Layout05Theme.background,
                          valueColor: const AlwaysStoppedAnimation(
                              Layout05Theme.primary),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('70%',
                                style: Layout05Theme.heading1
                                    .copyWith(fontSize: 40)),
                            const SizedBox(height: 4),
                            const Text('Consumido',
                                style:
                                    TextStyle(color: Layout05Theme.textGrey)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                          'Download', '350 GB', Layout05Theme.primary),
                      Container(
                          height: 40,
                          width: 1,
                          color: Colors.grey.withOpacity(0.2)),
                      _buildStatItem(
                          'Upload', '150 GB', Layout05Theme.secondary),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: Layout05Theme.cardDecoration,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Layout05Theme.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.calendar_today,
                        color: Layout05Theme.primary),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Ciclo Atual',
                            style: TextStyle(
                                color: Layout05Theme.textGrey, fontSize: 13)),
                        Text('01/12 - 31/12',
                            style: TextStyle(
                                color: Layout05Theme.textDark,
                                fontWeight: FontWeight.bold,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Layout05Theme.textGrey)),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
