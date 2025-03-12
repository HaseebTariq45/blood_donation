import '../providers/app_provider.dart';
import 'network_tracker_service.dart';

/// A simple service locator to access services throughout the app
class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  
  ServiceLocator._internal();
  
  // Service instances
  late NetworkTrackerService networkTracker;
  
  // Initialize services
  void initialize(AppProvider appProvider) {
    networkTracker = NetworkTrackerService(appProvider);
  }
}

// Global instance for easy access
final serviceLocator = ServiceLocator(); 