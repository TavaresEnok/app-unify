import 'package:flutter/material.dart';
import 'theme.dart';

class SuportePage extends StatelessWidget {
  const SuportePage({super.key});

  @override
  Widget build(BuildContext context) {
    final supportOptions = [
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'WhatsApp',
        'color': const Color(0xFF25D366)
      },
      {
        'icon': Icons.phone_outlined,
        'label': 'Ligar',
        'color': Layout05Theme.primary
      },
      {
        'icon': Icons.email_outlined,
        'label': 'Email',
        'color': Layout05Theme.secondary
      },
      {
        'icon': Icons.headset_mic_outlined,
        'label': 'Chat Online',
        'color': Colors.orange
      },
    ];

    return Scaffold(
      backgroundColor: Layout05Theme.background,
      appBar: AppBar(
        title: Text('Suporte', style: Layout05Theme.heading2),
        backgroundColor: Layout05Theme.background,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Layout05Theme.textDark),
      ),
      body: GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.1,
        ),
        itemCount: supportOptions.length,
        itemBuilder: (context, index) {
          final option = supportOptions[index];
          return Container(
            decoration: Layout05Theme.cardDecoration,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // Ação
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color:
                            (option['color'] as Color).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        option['icon'] as IconData,
                        color: option['color'] as Color,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      option['label'] as String,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Layout05Theme.textDark,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
