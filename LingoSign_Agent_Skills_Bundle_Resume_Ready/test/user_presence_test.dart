import 'package:flutter_test/flutter_test.dart';
import 'package:lingosign_ai/features/admin/domain/user_presence.dart';

void main() {
  final now = DateTime.utc(2026, 11, 25, 10);
  test('users without an acknowledged connection are offline', () {
    expect(isUserOnline([], now), isFalse);
  });
  test('any active device keeps the user online', () {
    expect(
      isUserOnline([
        now.subtract(const Duration(minutes: 5)),
        now.subtract(const Duration(seconds: 45)),
      ], now),
      isTrue,
    );
  });
  test('heartbeat expires at 90 seconds after a crash or network loss', () {
    expect(
      isUserOnline([now.subtract(const Duration(seconds: 89))], now),
      isTrue,
    );
    expect(
      isUserOnline([now.subtract(const Duration(seconds: 90))], now),
      isFalse,
    );
    expect(isUserOnline([now.add(const Duration(minutes: 5))], now), isFalse);
  });
}
