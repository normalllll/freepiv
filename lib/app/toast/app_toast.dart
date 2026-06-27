import 'package:flutter/material.dart';
import 'package:freepiv/core/utils/text_format.dart';
import 'package:freepiv/i18n/strings.g.dart';
import 'package:toastification/toastification.dart';

class AppToast {
  AppToast._();

  static void success(String message) {
    _show(type: ToastificationType.success, message: message, duration: const Duration(seconds: 3));
  }

  static void error(String message) {
    _show(type: ToastificationType.error, message: message, duration: const Duration(seconds: 4));
  }

  static void errorWithCause(String message, Object error) {
    AppToast.error(t.common.errorWithCause(message: message, cause: formatPixivError(error)));
  }

  static void info(String message) {
    _show(type: ToastificationType.info, message: message, duration: const Duration(seconds: 3));
  }

  static void warning(String message) {
    _show(type: ToastificationType.warning, message: message, duration: const Duration(seconds: 4));
  }

  static void _show({required ToastificationType type, required String message, required Duration duration}) {
    toastification.show(
      type: type,
      style: ToastificationStyle.minimal,
      title: Text(message),
      autoCloseDuration: duration,
      alignment: Alignment.topCenter,
      dragToClose: true,
      pauseOnHover: true,
    );
  }
}
