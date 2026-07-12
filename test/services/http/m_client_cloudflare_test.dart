import 'dart:async';

import 'package:flutter_inappwebview/flutter_inappwebview.dart'
    as flutter_inappwebview;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
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

  group('cloudflareSolveResult', () {
    test('retries after the challenge is cleared', () {
      expect(
        cloudflareSolveResult(timedOut: false, challengeRemaining: false),
        isTrue,
      );
    });

    test('does not retry while the challenge remains', () {
      expect(
        cloudflareSolveResult(timedOut: false, challengeRemaining: true),
        isFalse,
      );
    });

    test('does not retry after a timeout', () {
      expect(
        cloudflareSolveResult(timedOut: true, challengeRemaining: false),
        isFalse,
      );
    });
  });

  group('isCloudflare', () {
    test('does not treat an application JSON 403 as a challenge', () {
      final response = http.Response(
        '{"error":"forbidden"}',
        403,
        headers: {'server': 'cloudflare', 'content-type': 'application/json'},
      );

      expect(isCloudflare(response), isFalse);
    });

    test('detects a Cloudflare challenge response', () {
      final response = http.Response(
        '<html></html>',
        403,
        headers: {
          'server': 'cloudflare',
          'content-type': 'text/html',
          'cf-mitigated': 'challenge',
        },
      );

      expect(isCloudflare(response), isTrue);
    });
  });

  group('AsyncSingleFlight', () {
    test('shares one active operation for the same key', () async {
      final singleFlight = AsyncSingleFlight<String>();
      final operationStarted = Completer<void>();
      final releaseOperation = Completer<void>();
      var operationCount = 0;

      Future<String> operation() async {
        operationCount++;
        operationStarted.complete();
        await releaseOperation.future;
        return 'result';
      }

      final first = singleFlight.run('request', operation);
      await operationStarted.future;
      final second = singleFlight.run('request', operation);
      releaseOperation.complete();

      expect(await Future.wait([first, second]), ['result', 'result']);
      expect(operationCount, 1);
    });

    test('runs a new operation after the active one completes', () async {
      final singleFlight = AsyncSingleFlight<String>();
      var operationCount = 0;

      Future<String> operation() async => 'result-${++operationCount}';

      expect(await singleFlight.run('request', operation), 'result-1');
      expect(await singleFlight.run('request', operation), 'result-2');
    });
  });

  test('webview scripts are injected before page scripts run', () {
    final scripts = webviewInitialUserScripts(['first();', 'second();']);

    expect(scripts.map((script) => script.source), ['first();', 'second();']);
    expect(
      scripts.every(
        (script) =>
            script.injectionTime ==
            flutter_inappwebview.UserScriptInjectionTime.AT_DOCUMENT_START,
      ),
      isTrue,
    );
  });

  test('webview evaluation key depends on the page and scripts only', () {
    final first = webviewEvaluationKey('https://example.com', ['capture();']);
    final second = webviewEvaluationKey('https://example.com', ['capture();']);

    expect(first, second);
    expect(
      webviewEvaluationKey('https://other.example.com', ['capture();']),
      isNot(first),
    );
    expect(
      webviewEvaluationKey('https://example.com', ['other();']),
      isNot(first),
    );
  });
}
