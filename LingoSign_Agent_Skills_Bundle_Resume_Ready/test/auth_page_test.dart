import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/app/firebase_session.dart';
import 'package:lingosign_ai/app/theme/app_theme.dart';
import 'package:lingosign_ai/features/account/presentation/account_settings.dart';
import 'package:lingosign_ai/features/account/presentation/auth_page.dart';

class _TestAuth extends Fake implements FirebaseAuth {
  final logins = <String>[];
  final registrations = <String>[];

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    logins.add(email);
    throw FirebaseAuthException(code: 'invalid-credential');
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    registrations.add(email);
    throw FirebaseAuthException(code: 'email-already-in-use');
  }
}

class _UnusedFirestore extends Fake implements FirebaseFirestore {}

void main() {
  testWidgets(
    'Settings opens an email-only page and registration validates confirmation',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 680);
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final auth = _TestAuth();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            firebaseSessionProvider.overrideWithValue(
              FirebaseSession(auth, _UnusedFirestore(), null),
            ),
          ],
          child: MaterialApp(
            theme: AppTheme.dark,
            home: const Scaffold(body: AccountSettings()),
          ),
        ),
      );
      await tester.tap(find.widgetWithText(TextButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
      expect(find.byType(AuthPage), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(TextFormField), findsNWidgets(2));

      final switchMode = find.text('Chưa có tài khoản? Đăng ký');
      await tester.ensureVisible(switchMode);
      await tester.pumpAndSettle();
      await tester.tap(switchMode);
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      expect(fields, findsNWidgets(3));
      await tester.enterText(fields.at(0), 'learner@example.com');
      await tester.enterText(fields.at(1), 'fixture123');
      await tester.enterText(fields.at(2), 'different');
      final submit = find.widgetWithText(FilledButton, 'Đăng ký');
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(find.text('Mật khẩu không khớp.'), findsOneWidget);
      expect(auth.registrations, isEmpty);

      await tester.enterText(fields.at(2), 'fixture123');
      await tester.ensureVisible(submit);
      await tester.pumpAndSettle();
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(auth.registrations, ['learner@example.com']);
      expect(auth.logins, isEmpty);
      expect(find.text('Email này đã được đăng ký.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'login sends the email to Firebase and reports rejected credentials',
    (tester) async {
      final auth = _TestAuth();
      await tester.pumpWidget(MaterialApp(home: AuthPage(auth: auth)));
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), ' learner@example.com ');
      await tester.enterText(fields.at(1), 'fixture123');
      await tester.tap(find.widgetWithText(FilledButton, 'Đăng nhập'));
      await tester.pumpAndSettle();
      expect(auth.logins, ['learner@example.com']);
      expect(find.text('Email hoặc mật khẩu không đúng.'), findsOneWidget);
    },
  );
}
