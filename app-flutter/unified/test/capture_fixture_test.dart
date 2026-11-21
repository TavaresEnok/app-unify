import 'package:flutter_test/flutter_test.dart';
import '../tool/capture_preview.dart';

void main() {
  test('catalog configuration creates every supported theme', () {
    for (final id in [
      'layout_02',
      'layout_03',
      'layout_04',
      'layout_05',
      'layout_06'
    ]) {
      expect(DemoConfig(id).data.layoutType, id);
    }
  });
}
