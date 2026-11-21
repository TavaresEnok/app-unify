import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/in_app_notification.dart';
import '../providers/providers.dart';
import '../vibe/vibe_icon.dart';
import '../vibe/vibe_page_parts.dart';
import '../vibe/vibe_text.dart';
import '../vibe/vibe_tokens.dart';

/// Notificações (`PG.notificacoes` do layout aprovado): avisos do provedor
/// em um cartão; toque marca como lida e deslizar para a esquerda remove.
class SharedNotificationPage extends ConsumerStatefulWidget {
  const SharedNotificationPage({super.key});

  @override
  ConsumerState<SharedNotificationPage> createState() =>
      _SharedNotificationPageState();
}

class _SharedNotificationPageState
    extends ConsumerState<SharedNotificationPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider).loadNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(notificationProvider);
    final notifications = service.activeNotifications;
    final unread = service.unreadCount;
    final children = <Widget>[];
    if (service.isLoading) {
      children.add(const VibeCard(
          child: VibeEmpty(icon: 'bell', title: 'Consultando avisos…')));
    } else if (notifications.isEmpty) {
      children.add(const VibeCard(
          child: VibeEmpty(
              icon: 'bell',
              title: 'Nenhuma notificação',
              text: 'Os avisos do seu provedor aparecem aqui.')));
    } else {
      if (unread > 0) {
        children.add(Align(
          alignment: Alignment.centerLeft,
          child: VibePageButton(
            label: 'Marcar todas como lidas',
            icon: 'check',
            ghost: true,
            small: true,
            expand: false,
            onPressed: () => ref.read(notificationProvider).markAllAsRead(),
          ),
        ));
      }
      children.add(_NotificationList(items: notifications));
      children.add(const VibeNote(
          'Toque para marcar como lida. Deslize para a esquerda para remover.'));
    }
    return VibePageScaffold(
      title: 'Notificações',
      subtitle: unread == 0
          ? 'Tudo lido'
          : '$unread não lida${unread > 1 ? 's' : ''}',
      onBack: Navigator.of(context).canPop()
          ? () => Navigator.of(context).maybePop()
          : null,
      children: children,
    );
  }
}

/// Lista de avisos (`.g-nlist`), com fio entre os itens.
class _NotificationList extends ConsumerWidget {
  const _NotificationList({required this.items});

  final List<InAppNotification> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VibeTokens.of(context);
    return VibeCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(t.rad - 2 < 10 ? 10 : t.rad - 2),
        child: Column(children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: t.line),
            Dismissible(
              key: Key(items[i].id),
              direction: DismissDirection.endToStart,
              background: Container(
                color: const Color(0xFFD92D20),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const VibeIcon('g-x', size: 16, color: Colors.white),
                  const SizedBox(width: 6),
                  Text('Remover',
                      style: vibeText(t, 13, 700, color: Colors.white)),
                ]),
              ),
              onDismissed: (_) {
                ref.read(notificationProvider).deleteNotification(items[i].id);
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notificação removida')));
              },
              child: _NotificationTile(item: items[i]),
            ),
          ],
        ]),
      ),
    );
  }
}

/// Um aviso (`.g-ntf`), com marcador quando não lido.
class _NotificationTile extends ConsumerWidget {
  const _NotificationTile({required this.item});

  final InAppNotification item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = VibeTokens.of(context);
    return Semantics(
      button: true,
      label: '${item.read ? '' : 'Não lida. '}${item.title}. ${item.message}',
      excludeSemantics: true,
      child: Material(
        color: t.card,
        child: InkWell(
          onTap: () {
            if (!item.read) ref.read(notificationProvider).markAsRead(item.id);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Opacity(
                opacity: item.read ? .55 : 1,
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: t.ac.withValues(alpha: t.dark ? .22 : .15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: VibeIcon('bell', size: 20, color: t.at),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text.rich(TextSpan(children: [
                        TextSpan(text: item.title, style: vibeText(t, 14, 700)),
                        if (!item.read)
                          WidgetSpan(
                            alignment: PlaceholderAlignment.middle,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 6),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                    color: t.ac, shape: BoxShape.circle),
                              ),
                            ),
                          ),
                      ])),
                      const SizedBox(height: 2),
                      Text(item.message,
                          style: vibeText(t, 12.5, 500,
                              color: t.mut, height: 1.4)),
                      const SizedBox(height: 4),
                      Text(
                          DateFormat('dd/MM/yyyy HH:mm').format(item.createdAt),
                          style: vibeText(t, 11.5, 500, color: t.mut)),
                    ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
