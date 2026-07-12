import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/eval/javascript/utils.dart';

void main() {
  group('webviewEvaluationTime', () {
    test('uses the default when the optional argument is omitted', () {
      expect(
        webviewEvaluationTime(['url', <String, String>{}, <String>[]]),
        30,
      );
    });

    test('uses the supplied timeout', () {
      expect(
        webviewEvaluationTime(['url', <String, String>{}, <String>[], 45]),
        45,
      );
    });
  });
}
