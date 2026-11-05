import 'package:flutter/material.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';
import 'theme/tokens.dart';
import 'shell.dart';

class CadernoApp extends StatelessWidget {
  const CadernoApp({super.key, required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final c = state.dark ? BsColors.darkTheme : BsColors.light;
        return AppScope(
          state: state,
          child: MaterialApp(
            title: 'Caderno',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(c),
            builder: (context, child) => ToastLayer(child: child!),
            home: const Shell(),
          ),
        );
      },
    );
  }
}

/// Gives descendants access to [AppState]; rebuilds dependents when it changes.
class AppScope extends InheritedNotifier<AppState> {
  const AppScope({super.key, required AppState state, required super.child}) : super(notifier: state);
  static AppState of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AppScope>()!.notifier!;
}

extension AppCtx on BuildContext {
  AppState get app => AppScope.of(this);
}
