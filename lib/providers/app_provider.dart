import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/donation_model.dart';
import '../models/blood_request_model.dart';
import '../models/blood_bank_model.dart';

class AppProvider extends ChangeNotifier {
  // User data
  UserModel? _currentUser;
  UserModel get currentUser => _currentUser ?? UserModel.dummy();
  bool get isLoggedIn => _currentUser != null;

  // App theme
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;

  // Profile image error handling
  bool _profileImageLoadError = false;
  bool get profileImageLoadError => _profileImageLoadError;

  // Notification indicators
  bool _hasUnreadNotifications = true;
  bool get hasUnreadNotifications => _hasUnreadNotifications;

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

  // Login user
  void login(String email, String password) {
    // Simulated login - would connect to backend API in real app
    _currentUser = UserModel.dummy();
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
} 