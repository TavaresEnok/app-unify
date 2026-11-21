import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:app_provedor_unified/core/services/diagnostic_history_store.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('history is isolated by provider and account', () async {
    final first = DiagnosticHistoryStore('a', '1');
    await first.save({'id': 'test', 'summary': 'Result'});
    expect(await first.read(), hasLength(1));
    expect(await DiagnosticHistoryStore('b', '1').read(), isEmpty);
    expect(await DiagnosticHistoryStore('a', '2').read(), isEmpty);
    await DiagnosticHistoryStore('a', '2').save({'id': 'other'});
    await first.clear();
    expect(await DiagnosticHistoryStore('a', '2').read(), hasLength(1));
  });
  test('parallel saves retain summaries and duplicate IDs update in place',
      () async {
    final store = DiagnosticHistoryStore('a', '1');
    await Future.wait(List.generate(25, (i) => store.save({'id': '$i'})));
    expect(await store.read(), hasLength(20));
    await store.save({'id': '24', 'summary': 'updated'});
    final entries = await store.read();
    expect(entries, hasLength(20));
    expect(entries.first['summary'], 'updated');
    expect(entries.where((e) => e['id'] == '24'), hasLength(1));
  });
}
