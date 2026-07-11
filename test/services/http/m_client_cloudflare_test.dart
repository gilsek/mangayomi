import 'package:flutter_test/flutter_test.dart';
import 'package:mangayomi/services/http/m_client.dart';

void main() {
  group('userAgentForStoredCookie', () {
    test('uses the stored WebView user agent for cf_clearance', () {
      final userAgent = userAgentForStoredCookie(
        'session=abc; cf_clearance=clearance-token',
        'WebView2 User Agent',
        'Source User Agent',
      );

      expect(userAgent, 'WebView2 User Agent');
    });

    test('preserves the source user agent for ordinary cookies', () {
      final userAgent = userAgentForStoredCookie(
        'session=abc',
        'WebView2 User Agent',
        'Source User Agent',
      );

      expect(userAgent, 'Source User Agent');
    });

    test('uses the stored user agent when the source omitted one', () {
      final userAgent = userAgentForStoredCookie(
        'session=abc',
        'WebView2 User Agent',
        null,
      );

      expect(userAgent, 'WebView2 User Agent');
    });
  });
}
