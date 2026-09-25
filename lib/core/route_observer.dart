import 'package:flutter/material.dart';

/// Registered on GetMaterialApp so screens can react to being covered by
/// another route (e.g. Media feed muting its video when Create Post opens
/// on top of it) — not just to being fully disposed.
final RouteObserver<PageRoute> mediaRouteObserver = RouteObserver<PageRoute>();