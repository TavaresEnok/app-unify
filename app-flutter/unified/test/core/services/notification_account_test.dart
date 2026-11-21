import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_provedor_unified/core/models/in_app_notification.dart';
import 'package:app_provedor_unified/core/services/notification_service.dart';

InAppNotification notice(String id) => InAppNotification(
      id: id,
      type: NotificationType.info,
      title: id,
      message: 'Aviso do provedor',
      createdAt: DateTime(2026),
      read: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'notifications_v1': jsonEncode([notice('legado').toJson()]),
    });
  });

  test('avisos e estado de leitura são isolados entre contas e provedores',
      () async {
    final service = NotificationService();
    await service.setAccount('provedor-a', '111.111.111-11');
    expect(service.notifications, isEmpty);
    await service.addNotification(notice('aviso-a'));
    await service.markAsRead('aviso-a');

    await service.setAccount('provedor-a', '222.222.222-22');
    expect(service.notifications, isEmpty);
    await service.addNotification(notice('aviso-b'));

    await service.setAccount('provedor-b', '111.111.111-11');
    expect(service.notifications, isEmpty);
    service.clearAccount();
    await service.addNotification(notice('sem-conta'));
    expect(service.notifications, isEmpty);

    await service.setAccount('provedor-a', '11111111111');
    expect(service.notifications.map((n) => n.id), ['aviso-a']);
    expect(service.notifications.single.read, isTrue);
    await service.setAccount('provedor-a', '22222222222');
    expect(service.notifications.map((n) => n.id), ['aviso-b']);
  });

  test('aviso excluído continua excluído após sair e entrar', () async {
    final service = NotificationService();
    await service.setAccount('provedor', '11111111111');
    await service.addNotification(notice('publico'));
    service.deleteNotification('publico');
    await Future<void>.delayed(Duration.zero);
    service.clearAccount();
    await service.setAccount('provedor', '11111111111');
    await service.addNotification(notice('publico'));
    expect(service.notifications, isEmpty);
  });
}
