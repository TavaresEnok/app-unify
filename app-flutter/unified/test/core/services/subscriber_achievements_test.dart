import 'package:app_provedor_unified/core/services/subscriber_achievements.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('registra eventos simultâneos uma vez e isola assinantes', () async {
    await Future.wait([
      SubscriberAchievements.record('provedor', '123.456.789-00', AchievementEvent.diagnostic),
      SubscriberAchievements.record('provedor', '12345678900', AchievementEvent.speed),
      SubscriberAchievements.record('provedor', '12345678900', AchievementEvent.diagnostic),
    ]);
    final events = await SubscriberAchievements.load('provedor', '12345678900');
    expect(events.keys.toSet(), {'diagnostic', 'speed'});
    expect(await SubscriberAchievements.load('outro', '12345678900'), isEmpty);
    expect(await SubscriberAchievements.load('provedor', '99999999999'), isEmpty);
    final original = events['diagnostic'];
    await SubscriberAchievements.record('provedor', '12345678900', AchievementEvent.diagnostic);
    expect((await SubscriberAchievements.load('provedor', '12345678900'))['diagnostic'], original);
  });
}
