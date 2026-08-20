// lib/animations/page_transitions.dart
import 'package:flutter/material.dart';
import 'package:get/get_core/src/get_interface.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/src/extension_navigation.dart';

class PageTransitions {
  // Fade + Scale transition
  static Route<T> fadeScaleTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var fadeAnimation = animation.drive(tween);
        var scaleAnimation = animation.drive(Tween(begin: 0.95, end: 1.0).chain(CurveTween(curve: curve)));

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  // Slide from right
  static Route<T> slideFromRight<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Slide from bottom
  static Route<T> slideFromBottom<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  // Zoom transition
  static Route<T> zoomTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.easeOutBack;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var scaleAnimation = animation.drive(tween);

        return ScaleTransition(
          scale: scaleAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  // Fade transition
  static Route<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Slide from left
  static Route<T> slideFromLeft<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(-1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    );
  }

  // Elastic zoom transition
  static Route<T> elasticZoomTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.0;
        const end = 1.0;
        const curve = Curves.elasticOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var scaleAnimation = animation.drive(tween);

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 500),
    );
  }

  // Slide up with fade
  static Route<T> slideUpWithFade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 0.3);
        const end = Offset.zero;
        const curve = Curves.easeOutQuint;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 400),
    );
  }

  // Scale transition
  static Route<T> scaleTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = 0.8;
        const end = 1.0;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var scaleAnimation = animation.drive(tween);

        return ScaleTransition(
          scale: scaleAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }

  // Slide from right with fade
  static Route<T> slideRightWithFade<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeOutCubic;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        var offsetAnimation = animation.drive(tween);

        return SlideTransition(
          position: offsetAnimation,
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      transitionDuration: const Duration(milliseconds: 350),
    );
  }
}

// Extension for easy navigation with custom transitions
extension NavigationTransitionExtension on GetInterface {
  Future<T?> toWithFadeScale<T>(Widget page, {dynamic arguments}) {
    return Navigator.of(Get.context!).push<T>(
      PageTransitions.fadeScaleTransition<T>(page),
    );
  }

  Future<T?> toWithSlideRight<T>(Widget page, {dynamic arguments}) {
    return Navigator.of(Get.context!).push<T>(
      PageTransitions.slideFromRight<T>(page),
    );
  }

  Future<T?> toWithSlideLeft<T>(Widget page, {dynamic arguments}) {
    return Navigator.of(Get.context!).push<T>(
      PageTransitions.slideFromLeft<T>(page),
    );
  }

  Future<T?> toWithSlideBottom<T>(Widget page, {dynamic arguments}) {
    return Navigator.of(Get.context!).push<T>(
      PageTransitions.slideFromBottom<T>(page),
    );
  }

  Future<T?> toWithZoom<T>(Widget page, {dynamic arguments}) {
    return Navigator.of(Get.context!).push<T>(
      PageTransitions.zoomTransition<T>(page),
    );
  }

  Future<T?> toWithElasticZoom<T>(Widget page, {dynamic arguments}) {
    return Navigator.of(Get.context!).push<T>(
      PageTransitions.elasticZoomTransition<T>(page),
    );
  }

  Future<T?> toWithFade<T>(Widget page, {dynamic arguments}) {
    return Navigator.of(Get.context!).push<T>(
      PageTransitions.fadeTransition<T>(page),
    );
  }

  Future<T?> toWithSlideUpFade<T>(Widget page, {dynamic arguments}) {
    return Navigator.of(Get.context!).push<T>(
      PageTransitions.slideUpWithFade<T>(page),
    );
  }

  Future<T?> toWithScale<T>(Widget page, {dynamic arguments}) {
    return Navigator.of(Get.context!).push<T>(
      PageTransitions.scaleTransition<T>(page),
    );
  }

  Future<T?> toWithSlideRightFade<T>(Widget page, {dynamic arguments}) {
    return Navigator.of(Get.context!).push<T>(
      PageTransitions.slideRightWithFade<T>(page),
    );
  }
}