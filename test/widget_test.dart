import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fulbe/main.dart';
import 'package:fulbe/features/events/events_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  setUpAll(() async {
    // Mock shared preferences channel for Supabase storage
    SharedPreferences.setMockInitialValues({});

    await initializeDateFormatting('fr_FR', null);
    
    // Initialize Supabase with dummy config for tests
    await Supabase.initialize(
      url: 'https://placeholder.supabase.co',
      publishableKey: 'placeholder_key',
    );
  });

  testWidgets('App launches and shows welcome screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: FulbeConnectApp(hasValidConfig: true),
      ),
    );
    // Verify the app starts without crash
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('EventsScreen renders successfully', (WidgetTester tester) async {
    try {
      debugNetworkImageHttpClientProvider = () => MockHttpClient();

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: EventsScreen(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Événements'), findsOneWidget);
    } finally {
      debugNetworkImageHttpClientProvider = null;
    }
  });
}

class MockHttpClient implements HttpClient {
  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #getUrl || invocation.memberName == #openUrl) {
      return Future.value(MockHttpClientRequest());
    }
    throw UnimplementedError('MockHttpClient: ${invocation.memberName} is not mocked');
  }
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  final HttpHeaders headers = MockHttpHeaders();

  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #close) {
      return Future.value(MockHttpClientResponse());
    }
    if (invocation.memberName == #headers) {
      return headers;
    }
    throw UnimplementedError('MockHttpClientRequest: ${invocation.memberName} is not mocked');
  }
}

class MockHttpHeaders implements HttpHeaders {
  @override
  noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockHttpClientResponse extends Stream<List<int>> implements HttpClientResponse {
  static final List<int> _transparentImage = [
    137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 11, 73, 68, 65, 84, 8, 215, 99, 96, 0, 2, 0, 0, 5, 0, 1, 226, 38, 5, 159, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130
  ];

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream<List<int>>.fromIterable([_transparentImage]).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #statusCode) return 200;
    if (invocation.memberName == #contentLength) return _transparentImage.length;
    if (invocation.memberName == #headers) return MockHttpHeaders();
    if (invocation.memberName == #compressionState) return HttpClientResponseCompressionState.notCompressed;
    if (invocation.memberName == #persistentConnection) return true;
    throw UnimplementedError('MockHttpClientResponse: ${invocation.memberName} is not mocked');
  }
}
