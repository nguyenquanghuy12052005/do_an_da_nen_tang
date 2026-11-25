/// A heartbeat is online while the app is in the foreground and its most
/// recent server acknowledgement is less than 90 seconds old.
bool isUserOnline(Iterable<DateTime> acknowledgements, DateTime now) =>
    acknowledgements.any((time) {
      final age = now.toUtc().difference(time.toUtc());
      return !age.isNegative && age < const Duration(seconds: 90);
    });
