import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class SkeletonDashboardPage extends StatelessWidget {
  const SkeletonDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
        child: Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          enabled: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 100,
                            height: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 4),
                          Container(
                            width: 60,
                            height: 12,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Balance Card
              Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              const SizedBox(height: 24),

              // Quick Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(
                    4,
                    (index) => Column(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 40,
                              height: 10,
                              color: Colors.white,
                            ),
                          ],
                        )),
              ),
              const SizedBox(height: 28),

              // Plan Card
              Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              const SizedBox(height: 24),

              // Services List
              Column(
                children: List.generate(
                    3,
                    (index) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          width: double.infinity,
                          height: 70,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                        )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
