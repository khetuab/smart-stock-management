// lib/animations/get_custom_transitions.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// GetX-compatible versions of the transitions defined in
/// lib/animations/page_transitions.dart, so they can be used
/// directly as `customTransition:` on a GetPage.

class FadeScaleGetTransition extends CustomTransition {
  @override
  Widget buildTransition(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final fadeAnimation = animation.drive(
      CurveTween(curve: curve ?? Curves.easeOutCubic),
    );
    final scaleAnimation = animation.drive(
      Tween(begin: 0.95, end: 1.0)
          .chain(CurveTween(curve: curve ?? Curves.easeOutCubic)),
    );

    return FadeTransition(
      opacity: fadeAnimation,
      child: ScaleTransition(scale: scaleAnimation, child: child),
    );
  }
}

class SlideRightGetTransition extends CustomTransition {
  @override
  Widget buildTransition(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final offsetAnimation = animation.drive(
      Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: curve ?? Curves.easeOutCubic)),
    );
    return SlideTransition(position: offsetAnimation, child: child);
  }
}

class SlideLeftGetTransition extends CustomTransition {
  @override
  Widget buildTransition(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final offsetAnimation = animation.drive(
      Tween(begin: const Offset(-1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: curve ?? Curves.easeOutCubic)),
    );
    return SlideTransition(position: offsetAnimation, child: child);
  }
}

class SlideBottomGetTransition extends CustomTransition {
  @override
  Widget buildTransition(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final offsetAnimation = animation.drive(
      Tween(begin: const Offset(0.0, 1.0), end: Offset.zero)
          .chain(CurveTween(curve: curve ?? Curves.easeOutCubic)),
    );
    return SlideTransition(position: offsetAnimation, child: child);
  }
}

class ZoomGetTransition extends CustomTransition {
  @override
  Widget buildTransition(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final scaleAnimation = animation.drive(
      CurveTween(curve: curve ?? Curves.easeOutBack),
    );
    return ScaleTransition(scale: scaleAnimation, child: child);
  }
}

class ElasticZoomGetTransition extends CustomTransition {
  @override
  Widget buildTransition(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final scaleAnimation = animation.drive(
      CurveTween(curve: curve ?? Curves.elasticOut),
    );
    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

class FadeGetTransition extends CustomTransition {
  @override
  Widget buildTransition(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    return FadeTransition(opacity: animation, child: child);
  }
}

class SlideUpWithFadeGetTransition extends CustomTransition {
  @override
  Widget buildTransition(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final offsetAnimation = animation.drive(
      Tween(begin: const Offset(0.0, 0.3), end: Offset.zero)
          .chain(CurveTween(curve: curve ?? Curves.easeOutQuint)),
    );
    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

class ScaleGetTransition extends CustomTransition {
  @override
  Widget buildTransition(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final scaleAnimation = animation.drive(
      Tween(begin: 0.8, end: 1.0)
          .chain(CurveTween(curve: curve ?? Curves.easeOutCubic)),
    );
    return ScaleTransition(
      scale: scaleAnimation,
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}

class SlideRightWithFadeGetTransition extends CustomTransition {
  @override
  Widget buildTransition(
      BuildContext context,
      Curve? curve,
      Alignment? alignment,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child,
      ) {
    final offsetAnimation = animation.drive(
      Tween(begin: const Offset(1.0, 0.0), end: Offset.zero)
          .chain(CurveTween(curve: curve ?? Curves.easeOutCubic)),
    );
    return SlideTransition(
      position: offsetAnimation,
      child: FadeTransition(opacity: animation, child: child),
    );
  }
}