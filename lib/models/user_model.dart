import 'user_location_model.dart';

class UserModel {
  final String id;
  final String name;
  final String email;
  final String phoneNumber;
  final String bloodType;
  final String address;
  final String imageUrl;
  final bool isAvailableToDonate;
  final DateTime lastDonationDate;
  final UserLocationModel? location;
  final String city;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phoneNumber,
    required this.bloodType,
    required this.address,
    this.imageUrl = '',
    this.isAvailableToDonate = true,
    DateTime? lastDonationDate,
    this.location,
    this.city = '',
  }) : lastDonationDate =
           lastDonationDate ??
           DateTime.now().subtract(const Duration(days: 90));

  factory UserModel.dummy() {
    return UserModel(
      id: 'user123',
      name: 'John Doe',
      email: 'john.doe@example.com',
      phoneNumber: '+1234567890',
      bloodType: 'A+',
      address: '123 Main St, Cityville',
      imageUrl: '', // Empty string to use default icon in CircleAvatar
      isAvailableToDonate: true,
      lastDonationDate: DateTime.now().subtract(const Duration(days: 120)),
      city: 'Karachi',
    );
  }

  // Days until next donation eligibility (typical 90 days between donations)
  int get daysUntilNextDonation {
    final nextDonationDate = lastDonationDate.add(const Duration(days: 90));
    final daysRemaining = nextDonationDate.difference(DateTime.now()).inDays;
    return daysRemaining > 0 ? daysRemaining : 0;
  }

  // Check if user is eligible to donate
  bool get isEligibleToDonate =>
      daysUntilNextDonation == 0 && isAvailableToDonate;

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phoneNumber,
    String? bloodType,
    String? address,
    String? imageUrl,
    bool? isAvailableToDonate,
    DateTime? lastDonationDate,
    UserLocationModel? location,
    String? city,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      bloodType: bloodType ?? this.bloodType,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      isAvailableToDonate: isAvailableToDonate ?? this.isAvailableToDonate,
      lastDonationDate: lastDonationDate ?? this.lastDonationDate,
      location: location ?? this.location,
      city: city ?? this.city,
    );
  }

  // For debugging purposes
  @override
  String toString() {
    return 'UserModel{id: $id, name: $name, email: $email, phoneNumber: $phoneNumber, bloodType: $bloodType, '
        'address: $address, city: $city, isAvailableToDonate: $isAvailableToDonate, '
        'lastDonationDate: ${lastDonationDate.toIso8601String()}}';
  }
}
