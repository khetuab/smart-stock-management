import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:get/get.dart';

/// An exception whose toString() is just the message, so
/// `Get.snackbar(..., e.toString())` shows clean text with no "Exception:" prefix.
class AppException implements Exception {
  final String message;
  const AppException(this.message);

  @override
  String toString() => message;
}

class ErrorHelper {
  static String friendly(Object error) {
    if (error is AppException) return error.message;

    final text = error.toString().toLowerCase();
    final isNetwork = error is SocketException ||
        error is TimeoutException ||
        (error is DioException &&
            (error.type == DioExceptionType.connectionError ||
                error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.sendTimeout ||
                error.type == DioExceptionType.receiveTimeout)) ||
        text.contains('socketexception') ||
        text.contains('failed host lookup') ||
        text.contains('clientexception') ||
        text.contains('network is unreachable') ||
        text.contains('connection refused') ||
        text.contains('connection closed') ||
        text.contains('connection reset') ||
        text.contains('handshakeexception') ||
        text.contains('timed out');

    return isNetwork ? 'noInternet'.tr : 'somethingWentWrong'.tr;
  }
}