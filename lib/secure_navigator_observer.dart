import 'package:flutter/widgets.dart';
import 'package:no_screenshot/overlay_mode.dart';

/// Configuration for a single route's protection policy.
class SecureRouteConfig {
  const SecureRouteConfig({
    this.mode = OverlayMode.secure,
    this.blurRadius = 30.0,
    this.color = 0xFF000000,
  });

  final OverlayMode mode;
  final double blurRadius;
  final int color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SecureRouteConfig &&
          runtimeType == other.runtimeType &&
          mode == other.mode &&
          blurRadius == other.blurRadius &&
          color == other.color;

  @override
  int get hashCode => Object.hash(mode, blurRadius, color);
}

/// A [NavigatorObserver] that applies different protection levels per route.
///
/// ```dart
/// MaterialApp(
///   navigatorObservers: [
///     SecureNavigatorObserver(
///       policies: {
///         '/payment': SecureRouteConfig(mode: OverlayMode.secure),
///         '/profile': SecureRouteConfig(mode: OverlayMode.blur, blurRadius: 50),
///         '/home': SecureRouteConfig(mode: OverlayMode.none),
///       },
///     ),
///   ],
/// )
/// ```
class SecureNavigatorObserver extends NavigatorObserver {
  SecureNavigatorObserver({
    this.policies = const {},
    this.defaultConfig = const SecureRouteConfig(mode: OverlayMode.none),
  });

  final Map<String, SecureRouteConfig> policies;
  final SecureRouteConfig defaultConfig;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _applyPolicyForRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _applyPolicyForRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _applyPolicyForRoute(newRoute);
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _applyPolicyForRoute(previousRoute);
  }

  void _applyPolicyForRoute(Route<dynamic>? route) {
    final name = route?.settings.name;
    final config = (name != null ? policies[name] : null) ?? defaultConfig;
    applyOverlayMode(
      config.mode,
      blurRadius: config.blurRadius,
      color: config.color,
    );
  }
}
