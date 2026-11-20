import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vault_board/app.dart';

void main() {
  testWidgets('shows splash while Firebase initializes', (tester) async {
    final initialization = Completer<void>();

    await tester.pumpWidget(
      VaultApp(initializeFirebase: () => initialization.future),
    );

    expect(find.text('VAULT BOARD'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('offers retry after initialization failure', (tester) async {
    var attempts = 0;
    final retryInitialization = Completer<void>();

    await tester.pumpWidget(
      VaultApp(
        initializeFirebase: () {
          attempts++;
          if (attempts == 1) {
            return Future<void>.error(StateError('offline'));
          }
          return retryInitialization.future;
        },
      ),
    );
    await tester.pump();

    expect(find.text('Could not open the vault'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(attempts, 2);
  });
}
