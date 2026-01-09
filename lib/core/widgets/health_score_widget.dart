// Health Score Widget
// Visual display of network health score with stars and color-coded rating

import 'package:flutter/material.dart';
import '../models/network_health_score.dart';

class HealthScoreWidget extends StatelessWidget {
  final NetworkHealthScore score;
  final bool compact;

  const HealthScoreWidget({
    super.key,
    required this.score,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return _buildCompactView();
    }
    return _buildFullView();
  }

  Widget _buildCompactView() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: score.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: score.color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            score.totalScore.toString(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: score.color,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '/100',
            style: TextStyle(
              fontSize: 12,
              color: score.color.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 8),
          _buildStars(score.stars, 14),
        ],
      ),
    );
  }

  Widget _buildFullView() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            score.color.withOpacity(0.15),
            score.color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: score.color.withOpacity(0.3), width: 1.5),
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: score.color.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    score.grade,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: score.color,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${score.totalScore}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: score.color,
                            height: 1,
                          ),
                        ),
                        Text(
                          '/100',
                          style: TextStyle(
                            fontSize: 14,
                            color: score.color.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    _buildStars(score.stars, 16),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Message
          Text(
            score.message,
            style: TextStyle(
              fontSize: 13,
              color: score.color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          // Component scores
          _buildComponentScore('Velocidade', score.speedScore),
          const SizedBox(height: 8),
          _buildComponentScore('Latência', score.latencyScore),
          const SizedBox(height: 8),
          _buildComponentScore('Estabilidade', score.stabilityScore),
          const SizedBox(height: 8),
          _buildComponentScore('WiFi', score.wifiScore),
        ],
      ),
    );
  }

  Widget _buildComponentScore(String label, int value) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: score.color.withOpacity(0.8),
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: Stack(
            children: [
              // Background bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: score.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Progress bar
              FractionallySizedBox(
                widthFactor: value / 100,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: score.color,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            '$value',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: score.color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStars(int count, double size) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < count ? Icons.star : Icons.star_border,
          color: score.color,
          size: size,
        ),
      ),
    );
  }
}
