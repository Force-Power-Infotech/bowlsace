import 'dart:io';
import 'api_client.dart';
import '../utils/notification_service.dart';
import '../utils/navigation_service.dart';

class ApiErrorHandler {
  final NavigationService _navigationService;
  final NotificationService _notificationService;

  ApiErrorHandler(this._navigationService, this._notificationService);

  void handleError(dynamic error) {
    if (error is ApiException) {
      switch (error.statusCode) {
        case 400:
          _notificationService.showError('Invalid data: ${error.message}');
          break;
        case 401:
          _handleUnauthorized();
          break;
        case 403:
          _notificationService.showError(
            'You don\'t have permission to access this resource',
          );
          break;
        case 404:
          _notificationService.showError(
            'Resource not found: ${error.message}',
          );
          break;
        case 422:
          _notificationService.showError('Validation error: ${error.message}');
          break;
        default:
          _notificationService.showError('Error: ${error.message}');
      }
    } else if (error is NetworkException) {
      _notificationService.showError(
        'Network error. Please check your connection.',
      );
    } else if (error is SocketException) {
      _notificationService.showError(
        'Network error. Please check your connection.',
      );
    } else {
      _notificationService.showError('An unexpected error occurred');
      // Log error for debugging
      print('Unhandled error: $error');
    }
  }

  void handleAuthError(dynamic error) {
    if (error is ApiException) {
      if (error.statusCode == 401) {
        _notificationService.showError(
          'Invalid credentials. Please try again.',
        );
      } else {
        handleError(error);
      }
    } else {
      handleError(error);
    }
  }

  void _handleUnauthorized() {
    // Clear token
    TokenManager().clearToken();

    // Show message
    _notificationService.showWarning(
      'Your session has expired. Please log in again.',
    );

    // Navigate to login
    _navigationService.navigateToAndClear('/login');
  }
}
