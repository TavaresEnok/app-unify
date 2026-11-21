import 'package:flutter/material.dart';

import 'vibe_icon.dart';
import 'vibe_text.dart';
import 'vibe_tokens.dart';

/// Barra de navegação do layout aprovado.
///
/// `standard` e `circle` seguem `.nv` e `.nv.circ` do protótipo; `dock`
/// segue `.app-nav` da tela Dock de serviços.
class VibeNavBar extends StatelessWidget {
  const VibeNavBar(
      {super.key, required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  static const _labels = ['Início', 'Faturas', 'Conexão', 'Suporte'];
  static const _icons = ['home', 'file', 'wifi', 'chat'];
  static const _dockIcons = ['i-home', 'i-bill', 'i-wifi', 'i-support'];

  @override
  Widget build(BuildContext context) {
    final t = VibeTokens.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    if (t.nav == VibeNavStyle.dock) return _dock(context, t, bottom);
    return Container(
      decoration: BoxDecoration(
        color: t.card,
        border: Border(top: BorderSide(color: t.line)),
      ),
      padding: EdgeInsets.fromLTRB(6, 8, 6, 5 + bottom),
      child: Row(children: [
        for (var i = 0; i < 4; i++) Expanded(child: _item(context, t, i)),
      ]),
    );
  }

  Widget _item(BuildContext context, VibeTokens t, int i) {
    final on = i == selectedIndex;
    final circle = t.nav == VibeNavStyle.circle && on;
    return Semantics(
      button: true,
      selected: on,
      label: _labels[i],
      excludeSemantics: true,
      child: InkWell(
        onTap: () => onSelected(i),
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          height: 47,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (circle)
              Transform.translate(
                offset: const Offset(0, -2),
                child: Container(
                  width: 34,
                  height: 34,
                  decoration:
                      BoxDecoration(color: t.ac, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: VibeIcon(_icons[i], size: 18, color: t.on),
                ),
              )
            else
              Container(
                width: 58,
                height: 30,
                decoration: BoxDecoration(
                  color: on ? t.ac.withValues(alpha: .14) : null,
                  borderRadius: BorderRadius.circular(15),
                ),
                alignment: Alignment.center,
                child: VibeIcon(_icons[i], size: 22, color: on ? t.at : t.mut),
              ),
            SizedBox(height: circle ? 0 : 4),
            Text(_labels[i],
                maxLines: 1,
                style: vibeText(t, 11.5, 600,
                    color: on ? t.ink : t.mut, height: 1.1)),
          ]),
        ),
      ),
    );
  }

  Widget _dock(BuildContext context, VibeTokens t, double bottom) {
    final p = t.dock!;
    return Container(
      decoration: BoxDecoration(
        color: p.base,
        border: Border(top: BorderSide(color: p.hair)),
      ),
      padding: EdgeInsets.fromLTRB(6, 4, 6, 5 + bottom),
      child: Row(children: [
        for (var i = 0; i < 4; i++)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.5),
              child: Semantics(
                button: true,
                selected: i == selectedIndex,
                label: _labels[i],
                excludeSemantics: true,
                child: Material(
                  color: i == selectedIndex ? p.soft : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => onSelected(i),
                    child: SizedBox(
                      height: 47,
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            VibeIcon(_dockIcons[i],
                                size: 20,
                                strokeWidth: i == selectedIndex ? 2 : 1.7,
                                color: i == selectedIndex ? p.brand : p.muted),
                            const SizedBox(height: 3),
                            Text(_labels[i],
                                maxLines: 1,
                                style: vibeText(
                                    t, 12, i == selectedIndex ? 700 : 550,
                                    color:
                                        i == selectedIndex ? p.brand : p.muted,
                                    height: 1.14,
                                    letterSpacingEm: -.0175)),
                          ]),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}
