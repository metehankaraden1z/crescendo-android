import 'package:flutter/widgets.dart';

import 'session/session_controller.dart';

/// Makes the session (and through it the API) available to every screen.
class AppScope extends InheritedNotifier<SessionController> {
  const AppScope({super.key, required SessionController session, required super.child})
      : super(notifier: session);

  /// Rebuilds the caller when the session changes (login/logout).
  static SessionController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;

  /// Reads the session without subscribing to changes (for event handlers).
  static SessionController read(BuildContext context) =>
      context.getInheritedWidgetOfExactType<AppScope>()!.notifier!;
}
