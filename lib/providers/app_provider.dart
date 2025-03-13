import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/donation_model.dart';
import '../models/blood_request_model.dart';
import '../models/blood_bank_model.dart';
import '../models/data_usage_model.dart';
import '../utils/location_service.dart';

class AppProvider extends ChangeNotifier {
  // User data
  UserModel? _currentUser;
  UserModel get currentUser => _currentUser ?? UserModel.dummy();
  bool get isLoggedIn => _currentUser != null;

  // App theme
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // App locale/language
  Locale _locale = const Locale('en', 'US');
  Locale get locale => _locale;
  String _selectedLanguage = 'English';
  String get selectedLanguage => _selectedLanguage;

  // Location settings
  bool _isLocationEnabled = false;
  bool get isLocationEnabled => _isLocationEnabled;

  // Profile image error handling
  bool _profileImageLoadError = false;
  bool get profileImageLoadError => _profileImageLoadError;

  // Notification indicators
  bool _hasUnreadNotifications = true;
  bool get hasUnreadNotifications => _hasUnreadNotifications;

  // Data usage tracking
  DataUsageModel _dataUsage = DataUsageModel.empty();
  DataUsageModel get dataUsage => _dataUsage;

  // Donation history
  List<DonationModel> _donations = [];
  List<DonationModel> get donations => _donations;
  
  // Current user's donations
  List<DonationModel> _userDonations = [];
  List<DonationModel> get userDonations => _userDonations;

  // Blood requests
  List<BloodRequestModel> _bloodRequests = [];
  List<BloodRequestModel> get bloodRequests => _bloodRequests;

  // Blood banks
  List<BloodBankModel> _bloodBanks = [];
  List<BloodBankModel> get bloodBanks => _bloodBanks;

  // Blood donors
  List<UserModel> _donors = [];
  List<UserModel> get donors => _donors;

  // App theme mode
  ThemeMode _themeMode = ThemeMode.light;
  ThemeMode get themeMode => _themeMode;

  // Constructor - load dummy data for UI demo
  AppProvider() {
    _loadDummyData();
    _loadDataUsage();
  }

  // Load dummy data for demonstration
  void _loadDummyData() {
    _currentUser = UserModel.dummy();
    _donations = DonationModel.getDummyList(10);
    _userDonations = DonationModel.getDummyList(5);
    _bloodRequests = BloodRequestModel.getDummyList();
    _bloodBanks = BloodBankModel.getDummyList();
    
    // Generate dummy donors
    _donors = List.generate(15, (index) {
      final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
      return UserModel(
        id: 'donor_$index',
        name: 'Donor ${index + 1}',
        email: 'donor${index + 1}@example.com',
        phone: '+1234${index}7890',
        bloodType: bloodTypes[index % bloodTypes.length],
        address: '${index + 100} Main St, City',
        imageUrl: 'assets/images/avatar_${(index % 8) + 1}.png',
        isAvailableToDonate: index % 3 != 0,
        lastDonationDate: DateTime.now().subtract(Duration(days: 90 + index * 5)),
      );
    });
    
    // Set the current user to also have a local image
    _currentUser = _currentUser!.copyWith(
      imageUrl: 'assets/images/avatar_1.png',
    );
  }
  
  // Load data usage from shared preferences
  Future<void> _loadDataUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final totalBytes = prefs.getInt('data_usage_total_bytes') ?? 0;
      final wifiBytes = prefs.getInt('data_usage_wifi_bytes') ?? 0;
      final mobileBytes = prefs.getInt('data_usage_mobile_bytes') ?? 0;
      final lastResetTimestamp = prefs.getInt('data_usage_last_reset');
      
      final lastReset = lastResetTimestamp != null 
          ? DateTime.fromMillisecondsSinceEpoch(lastResetTimestamp)
          : DateTime.now();
      
      _dataUsage = DataUsageModel(
        totalBytes: totalBytes,
        wifiBytes: wifiBytes,
        mobileBytes: mobileBytes,
        lastReset: lastReset,
      );
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading data usage: $e');
      // If there's an error, start with empty data
      _dataUsage = DataUsageModel.empty();
    }
  }
  
  // Public method to refresh data usage
  Future<void> refreshDataUsage() async {
    await _loadDataUsage();
  }
  
  // Save data usage to shared preferences
  Future<void> _saveDataUsage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('data_usage_total_bytes', _dataUsage.totalBytes);
      await prefs.setInt('data_usage_wifi_bytes', _dataUsage.wifiBytes);
      await prefs.setInt('data_usage_mobile_bytes', _dataUsage.mobileBytes);
      await prefs.setInt('data_usage_last_reset', 
          _dataUsage.lastReset.millisecondsSinceEpoch);
    } catch (e) {
      debugPrint('Error saving data usage: $e');
    }
  }

  // Track network data usage
  void recordDataUsage(int bytesUsed, bool isWifi) {
    if (isWifi) {
      _dataUsage = _dataUsage.copyWith(
        totalBytes: _dataUsage.totalBytes + bytesUsed,
        wifiBytes: _dataUsage.wifiBytes + bytesUsed,
      );
    } else {
      _dataUsage = _dataUsage.copyWith(
        totalBytes: _dataUsage.totalBytes + bytesUsed,
        mobileBytes: _dataUsage.mobileBytes + bytesUsed,
      );
    }
    notifyListeners();
    _saveDataUsage(); // Save data whenever it changes
  }

  // Reset data usage statistics
  void resetDataUsage() {
    _dataUsage = DataUsageModel.empty();
    notifyListeners();
    _saveDataUsage();
  }

  // Change app language
  void setLanguage(String language) {
    _selectedLanguage = language;
    
    switch (language) {
      case 'English':
        _locale = const Locale('en', 'US');
        break;
      case 'Spanish':
        _locale = const Locale('es', 'ES');
        break;
      case 'French':
        _locale = const Locale('fr', 'FR');
        break;
      case 'Arabic':
        _locale = const Locale('ar', 'SA');
        break;
      case 'Urdu':
        _locale = const Locale('ur', 'PK');
        break;
      default:
        _locale = const Locale('en', 'US');
    }
    
    notifyListeners();
  }

  // Login user
  void login(String email, String password) {
    // Simulated login - would connect to backend API in real app
    _currentUser = UserModel.dummy();
    notifyListeners();
  }
  
  // Register a new user
  void registerUser(UserModel user, String password) {
    // BACKEND IMPLEMENTATION NOTE:
    // In a real app, this would make an API call to register the user
    // with the provided information and password
    
    // For this demo, we just store the user object locally
    _currentUser = user;
    
    // Add the new user to the donors list as well
    _donors.add(user);
    
    notifyListeners();
  }

  // Logout user
  void logout() {
    _currentUser = null;
    notifyListeners();
  }

  // Update user profile
  void updateUserProfile(UserModel updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  // Toggle user availability to donate
  void toggleDonationAvailability() {
    if (_currentUser != null) {
      _currentUser = _currentUser!.copyWith(
        isAvailableToDonate: !_currentUser!.isAvailableToDonate,
      );
      notifyListeners();
    }
  }
  
  // Add a new donation for the current user
  void addDonation(DonationModel donation) {
    _userDonations.add(donation);
    _donations.add(donation);
    notifyListeners();
  }
  
  // Cancel a donation appointment
  void cancelDonation(String donationId) {
    final donationIndex = _userDonations.indexWhere((d) => d.id == donationId);
    if (donationIndex != -1) {
      final updatedDonation = DonationModel(
        id: _userDonations[donationIndex].id,
        donorId: _userDonations[donationIndex].donorId,
        donorName: _userDonations[donationIndex].donorName,
        bloodType: _userDonations[donationIndex].bloodType,
        date: _userDonations[donationIndex].date,
        centerName: _userDonations[donationIndex].centerName,
        address: _userDonations[donationIndex].address,
        recipientId: _userDonations[donationIndex].recipientId,
        recipientName: _userDonations[donationIndex].recipientName,
        status: 'Cancelled',
      );
      
      _userDonations[donationIndex] = updatedDonation;
      
      // Update in global donations list too
      final globalIndex = _donations.indexWhere((d) => d.id == donationId);
      if (globalIndex != -1) {
        _donations[globalIndex] = updatedDonation;
      }
      
      notifyListeners();
    }
  }

  // Add new blood request
  void addBloodRequest(BloodRequestModel request) {
    _bloodRequests.add(request);
    notifyListeners();
  }

  // Filter donors by blood type and availability
  List<UserModel> filterDonors({String? bloodType, bool? onlyAvailable}) {
    return _donors.where((donor) {
      bool matchesBloodType = bloodType == null || donor.bloodType == bloodType;
      bool matchesAvailability = onlyAvailable == null || !onlyAvailable || donor.isAvailableToDonate;
      return matchesBloodType && matchesAvailability;
    }).toList();
  }

  // Filter blood banks by distance
  List<BloodBankModel> filterBloodBanksByDistance(int maxDistance) {
    return _bloodBanks.where((bank) => bank.distance <= maxDistance).toList();
  }

  // Toggle theme mode
  void toggleThemeMode() {
    _isDarkMode = !_isDarkMode;
    _themeMode = _isDarkMode ? ThemeMode.dark : ThemeMode.light;
    notifyListeners();
  }

  // Mark profile image as having a load error
  void setProfileImageLoadError(bool hasError) {
    _profileImageLoadError = hasError;
    notifyListeners();
  }

  // Mark all notifications as read
  void markAllNotificationsAsRead() {
    _hasUnreadNotifications = false;
    notifyListeners();
  }

  // Location methods
  Future<void> checkLocationStatus() async {
    final locationService = LocationService();
    _isLocationEnabled = await locationService.isLocationEnabled();
    notifyListeners();
  }

  Future<bool> enableLocation() async {
    final locationService = LocationService();
    bool success = await locationService.requestLocationPermission();
    _isLocationEnabled = success;
    notifyListeners();
    return success;
  }

  Future<void> disableLocation() async {
    final locationService = LocationService();
    await locationService.disableLocation();
    _isLocationEnabled = false;
    notifyListeners();
  }

  // Add to the initialize method
  Future<void> initialize() async {
    // ... (existing initialization code) ...
    
    // Initialize location status
    await checkLocationStatus();
  }
} 