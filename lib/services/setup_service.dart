// lib/services/setup_service.dart
import 'package:flutter/foundation.dart';

class SetupService extends ChangeNotifier {
  bool _isSetupComplete = false;

  bool get isSetupComplete => _isSetupComplete;

  void completeSetup() {
    _isSetupComplete = true;
    notifyListeners();
  }
}