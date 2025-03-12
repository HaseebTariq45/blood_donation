import 'package:intl/intl.dart';

class DonationModel {
  final String id;
  final String donorId;
  final String donorName;
  final String bloodType;
  final DateTime date;
  final String centerName;
  final String address;
  final String recipientId;
  final String recipientName;
  final String status; // Completed, Pending, Cancelled

  DonationModel({
    required this.id,
    required this.donorId,
    required this.donorName,
    required this.bloodType,
    required this.date,
    required this.centerName,
    required this.address,
    this.recipientId = '',
    this.recipientName = '',
    this.status = 'Completed',
  });

  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);

  factory DonationModel.dummy(int index) {
    final statuses = ['Completed', 'Pending', 'Cancelled'];
    final bloodTypes = ['A+', 'B+', 'AB+', 'O+', 'A-', 'B-', 'AB-', 'O-'];
    final centers = [
      'City Blood Bank',
      'Central Hospital',
      'Red Cross Center',
      'Community Donation Center',
      'Medical College Hospital'
    ];
    
    final randomDays = (index + 1) * 30;
    final randomStatus = statuses[index % statuses.length];
    final randomBloodType = bloodTypes[index % bloodTypes.length];
    final randomCenter = centers[index % centers.length];
    
    return DonationModel(
      id: 'donation_$index',
      donorId: 'donor_1',
      donorName: 'John Doe',
      bloodType: randomBloodType,
      date: DateTime.now().subtract(Duration(days: randomDays)),
      centerName: randomCenter,
      address: '123 Main St, City, Country',
      recipientId: index % 2 == 0 ? 'recipient_$index' : '',
      recipientName: index % 2 == 0 ? 'Hospital Patient' : '',
      status: randomStatus,
    );
  }

  static List<DonationModel> getDummyList(int count) {
    return List.generate(count, (index) => DonationModel.dummy(index));
  }
} 