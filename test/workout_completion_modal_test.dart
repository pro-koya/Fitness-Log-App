import 'dart:async';

import 'package:fitness_log_app/features/workout_completion/models/workout_completion_result.dart';
import 'package:fitness_log_app/features/workout_completion/workout_completion_modal.dart';
import 'package:fitness_log_app/l10n/app_localizations.dart';
import 'package:fitness_log_app/providers/sync_providers.dart';
import 'package:fitness_log_app/services/supabase_auth_service.dart';
import 'package:fitness_log_app/services/sync_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('Google sign-in keeps the Google button busy and then syncs', (
    tester,
  ) async {
    final auth = _FakeAuthService();
    final sync = _FakeSyncService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          supabaseAuthServiceProvider.overrideWithValue(auth),
          syncServiceProvider.overrideWithValue(sync),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: WorkoutCompletionModal(result: _result, onClose: () {}),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Sign in with Google & sync'));
    await tester.pump();

    expect(auth.googleSignInCount, 1);
    expect(
      find.widgetWithText(OutlinedButton, 'Signing in...'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Sign in with Apple & sync'),
          )
          .onPressed,
      isNull,
    );
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'OK'))
          .onPressed,
      isNull,
    );
    expect(sync.syncCallCount, 0);

    auth.completeGoogle(const AuthSuccess());
    await tester.pump();

    expect(sync.syncCallCount, 1);
    expect(
      find.widgetWithText(OutlinedButton, 'Signing in...'),
      findsOneWidget,
    );

    sync.complete(null);
    await tester.pump();

    expect(find.text('Synced data to cloud'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, 'OK'))
          .onPressed,
      isNotNull,
    );
  });
}

const _result = WorkoutCompletionResult(
  sessionId: 1,
  exerciseCount: 1,
  setCount: 3,
  totalVolume: 1200,
  message: 'Nice work',
  streak: 1,
  weeklyCount: 1,
  unit: 'kg',
  exerciseDetails: [
    ExerciseSummaryItem(name: 'Bench Press', setCount: 3, topWeight: 80),
  ],
);

class _FakeAuthService extends SupabaseAuthService {
  var signedIn = false;
  var googleSignInCount = 0;
  final _googleCompleter = Completer<AuthResult>();

  @override
  bool get isSignedIn => signedIn;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  Future<AuthResult> signInWithGoogle() async {
    googleSignInCount += 1;
    final result = await _googleCompleter.future;
    if (result is AuthSuccess) {
      signedIn = true;
    }
    return result;
  }

  void completeGoogle(AuthResult result) {
    _googleCompleter.complete(result);
  }
}

class _FakeSyncService extends SyncService {
  _FakeSyncService()
    : super(authService: _FakeAuthService(), remoteStore: _FakeRemoteStore());

  var syncCallCount = 0;
  final _completer = Completer<String?>();

  @override
  Future<String?> syncNow() {
    syncCallCount += 1;
    return _completer.future;
  }

  void complete(String? error) {
    _completer.complete(error);
  }
}

class _FakeRemoteStore implements SyncRemoteStore {
  @override
  Future<void> deleteIds(String tableName, List<String> ids) async {}

  @override
  Future<List<Map<String, dynamic>>> fetchAll(
    String tableName,
    String userId,
  ) async {
    return const [];
  }

  @override
  Future<void> upsert(
    String tableName,
    List<Map<String, dynamic>> rows,
  ) async {}
}
