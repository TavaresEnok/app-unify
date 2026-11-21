import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/layout_registry.dart';
import '../../providers/providers.dart';
import 'homes/home_blocks.dart';
import 'homes/home_centered.dart';
import 'homes/home_dock.dart';
import 'homes/home_ribbon.dart';
import 'homes/home_sheet.dart';

/// Início do assinante: uma das cinco telas definitivas do layout aprovado
/// (layout-app/vibe-5-definitivas.html), na ordem do ranking:
/// 1º Histórico na folha (layout_02), 2º Dock de serviços (layout_03),
/// 3º Blocos escuros (layout_04), 4º Faixa e fatura (layout_05) e
/// 5º Topo centralizado (layout_06).
class CustomerHomePage extends ConsumerWidget {
  const CustomerHomePage({
    super.key,
    this.layoutType,
    required this.onNavigate,
    this.onRefresh,
  });

  final String? layoutType;
  final ValueChanged<String> onNavigate;
  final Future<void> Function()? onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final layout = LayoutRegistry.normalize(layoutType ??
        ref.watch(configurationProvider).providerConfig?.layoutType);
    return switch (layout) {
      'layout_02' =>
        VibeSheetHome(onNavigate: onNavigate, onRefresh: onRefresh),
      'layout_03' => VibeDockHome(onNavigate: onNavigate, onRefresh: onRefresh),
      'layout_04' =>
        VibeBlocksHome(onNavigate: onNavigate, onRefresh: onRefresh),
      'layout_05' =>
        VibeRibbonHome(onNavigate: onNavigate, onRefresh: onRefresh),
      _ => VibeCenteredHome(onNavigate: onNavigate, onRefresh: onRefresh),
    };
  }
}
