import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../l10n/app_localizations.dart';
import '../errors/app_exception.dart';

/// Converts known errors to translations. Unknown server text is never shown.
class ErrorLocalizer {
  ErrorLocalizer._();

  static String localize(String serverMessage, AppLocalizations l10n) =>
      _knownMessage(serverMessage, l10n) ?? l10n.genericErrorFallback;

  static String forException(Object error, AppLocalizations l10n) {
    if (error is DioException) {
      return forException(
        AppException.fromDio(error, fallbackMessage: 'Request failed'),
        l10n,
      );
    }
    if (error is SocketException) return l10n.errorNetworkUnavailable;
    if (error is TimeoutException) return l10n.errorRequestTimeout;
    if (error is! AppException) return l10n.genericErrorFallback;

    switch (error.type) {
      case AppExceptionType.network:
        return l10n.errorNetworkUnavailable;
      case AppExceptionType.timeout:
        return l10n.errorRequestTimeout;
      case AppExceptionType.cancelled:
        return l10n.errorRequestCancelled;
      case null:
        break;
    }
    final status = error.statusCode;
    if (status != null && status >= 500 && status < 600) {
      return l10n.errorServerUnavailable;
    }
    if (status == 429) {
      return error.requestPath?.endsWith('/content/shared-by-me/') == true
          ? l10n.errorShareLimitReached
          : l10n.errorTooManyRequests;
    }
    if (status == 403) return l10n.errorAccessDenied;
    if (status == 401) {
      return error.requestPath?.endsWith('/authentication/users/login/') == true
          ? l10n.errorInvalidCredentials
          : l10n.errorSessionExpiredRelogin;
    }

    // The local incomplete-code key belongs to the form, not the API contract.
    if (error.messageKey == 'local_incomplete_otp') {
      return l10n.enterCompleteOtpCode;
    }
    if (error.messageKey == 'you_can_pin_maximum_5_folders') {
      return l10n.maxPinnedFolders;
    }
    final fields = error.errors;
    if (fields != null) {
      for (final entry in fields.entries) {
        final value = entry.value.toString().toLowerCase();
        if ((entry.key == 'phone_number' || entry.key == 'phone') &&
            (value.contains('already exists') ||
                value.contains('already registered') ||
                value.contains('уже существует') ||
                value.contains('allaqachon mavjud'))) {
          return l10n.errorUserAlreadyExists;
        }
      }
    }
    final known = _knownMessage(error.message, l10n);
    if (known != null) return known;
    if (status == 404) return l10n.errorResourceNotFound;
    if (status == 409) return l10n.errorItemAlreadyExists;
    if (status == 400 || status == 422) return l10n.errorValidation;
    return l10n.genericErrorFallback;
  }

  static String? _knownMessage(String message, AppLocalizations l10n) {
    final lower = message.toLowerCase().trim();
    // Older upload errors wrap transport failures in AppException.message.
    // Recognize their category without exposing paths or hostnames.
    if (lower.contains('timeoutexception') || lower.contains('timed out')) {
      return l10n.errorRequestTimeout;
    }
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection refused') ||
        lower.contains('connection reset') ||
        lower.contains('network is unreachable')) {
      return l10n.errorNetworkUnavailable;
    }
    if (lower.contains('invalid phone_number or password') ||
        lower.contains('invalid credentials') ||
        lower.contains('incorrect password') ||
        lower.contains('invalid_credentials')) {
      return l10n.errorInvalidCredentials;
    }
    if (lower.contains('still valid') &&
        (lower.contains('otp') || lower.contains('code'))) {
      return l10n.errorOtpStillValid;
    }
    final isCode = lower.contains('otp') || lower.contains('verification code');
    if (isCode &&
        (lower.contains('expired') || lower.contains('has expired'))) {
      return l10n.errorOtpExpired;
    }
    if (lower.contains('invalid code') ||
        lower.contains('wrong code') ||
        (isCode &&
            (lower.contains('invalid otp') ||
                lower.contains('incorrect code')))) {
      return l10n.errorInvalidCode;
    }
    if (lower.contains('user already exists') ||
        lower.contains('phone already') ||
        lower.contains('phone_number already')) {
      return l10n.errorUserAlreadyExists;
    }
    if (lower.contains('user not found') ||
        lower.contains('account not found')) {
      return l10n.errorUserNotFound;
    }
    if (lower.contains('session expired') ||
        lower.contains('token expired') ||
        lower.contains('token has expired')) {
      return l10n.errorSessionExpired;
    }
    if ((lower.contains('folder') || lower.contains('file')) &&
        lower.contains('already exists')) {
      return l10n.errorItemAlreadyExists;
    }
    if ((lower.contains('folder') || lower.contains('file')) &&
        lower.contains('not found')) {
      return l10n.errorResourceNotFound;
    }
    if (lower == 'cannot modify sync folder') return l10n.syncFolderReadOnly;
    if (lower == 'cannot delete system folder') {
      return l10n.errorSystemFolderProtected;
    }
    if (lower == 'максимум 5 закреплённых папок') return l10n.maxPinnedFolders;
    return null;
  }
}
