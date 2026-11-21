import 'package:flutter/material.dart';
import '../theme/customer_style.dart';

class CustomerCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  const CustomerCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(
                Theme.of(context).extension<CustomerStyle>()?.radius ?? 20),
            boxShadow: Theme.of(context).extension<CustomerStyle>()?.shadows,
            border: Border.all(
                color: Theme.of(context).extension<CustomerStyle>()?.border ??
                    Theme.of(context).colorScheme.outlineVariant)),
        child: child,
      );
}

class CustomerSection extends StatelessWidget {
  final String title;
  final String? description;
  const CustomerSection(this.title, {super.key, this.description});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          if (description != null) ...[
            const SizedBox(height: 6),
            Text(description!,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.5))
          ],
        ]),
      );
}

class CustomerAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const CustomerAction(
      {super.key,
      required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: colors.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: colors.outlineVariant)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(children: [
                  Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                          color: colors.primary.withValues(alpha: .1),
                          borderRadius: BorderRadius.circular(14)),
                      child: Icon(icon,
                          color: Theme.of(context)
                                  .extension<CustomerStyle>()
                                  ?.iconColor ??
                              colors.onSurface,
                          size: 24)),
                  const SizedBox(width: 16),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(subtitle,
                            style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 14,
                                height: 1.4)),
                      ])),
                  const SizedBox(width: 8),
                  Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
                ]),
              )),
        ));
  }
}

class CustomerList extends StatelessWidget {
  final List<Widget> children;
  final Future<void> Function()? onRefresh;
  const CustomerList({super.key, required this.children, this.onRefresh});
  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
        builder: (context, constraints) => ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                  ((constraints.maxWidth - 680) / 2).clamp(20, double.infinity),
                  20,
                  ((constraints.maxWidth - 680) / 2).clamp(20, double.infinity),
                  32),
              children: children,
            ));
    return onRefresh == null
        ? content
        : RefreshIndicator(onRefresh: onRefresh!, child: content);
  }
}
