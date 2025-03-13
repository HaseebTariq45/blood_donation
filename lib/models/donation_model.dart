import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    this.status = 'Pending',
  });

  String get formattedDate => DateFormat('MMM dd, yyyy').format(date);

  // Create a copy of this donation with updated fields
  DonationModel copyWith({
    String? id,
    String? donorId,
    String? donorName,
    String? bloodType,
    DateTime? date,
    String? centerName,
    String? address,
    String? recipientId,
    String? recipientName,
    String? status,
  }) {
    return DonationModel(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      donorName: donorName ?? this.donorName,
      bloodType: bloodType ?? this.bloodType,
      date: date ?? this.date,
      centerName: centerName ?? this.centerName,
      address: address ?? this.address,
      recipientId: recipientId ?? this.recipientId,
      recipientName: recipientName ?? this.recipientName,
      status: status ?? this.status,
    );
  }

  // Convert DonationModel to Map for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donorId': donorId,
      'donorName': donorName,
      'bloodType': bloodType,
      'date': date.millisecondsSinceEpoch,
      'centerName': centerName,
      'address': address,
      'recipientId': recipientId,
      'recipientName': recipientName,
      'status': status,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  // Create DonationModel from Firestore document
  factory DonationModel.fromJson(Map<String, dynamic> json) {
    // Handle different date formats from Firestore
    DateTime parsedDate;
    if (json['date'] is Timestamp) {
      parsedDate = (json['date'] as Timestamp).toDate();
    } else if (json['date'] is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(json['date']);
    } else {
      parsedDate = DateTime.now();
    }
    
    return DonationModel(
      id: json['id'] ?? '',
      donorId: json['donorId'] ?? '',
      donorName: json['donorName'] ?? '',
      bloodType: json['bloodType'] ?? '',
      date: parsedDate,
      centerName: json['centerName'] ?? '',
      address: json['address'] ?? '',
      recipientId: json['recipientId'] ?? '',
      recipientName: json['recipientName'] ?? '',
      status: json['status'] ?? 'Pending',
    );
  }

  // Factory method to create a new donation for a specific donor and blood center
  factory DonationModel.create({
    required String donorId,
    required String donorName,
    required String bloodType,
    required String centerName,
    required String address,
  }) {
    return DonationModel(
      id: '',  // Will be assigned by Firestore
      donorId: donorId,
      donorName: donorName,
      bloodType: bloodType,
      date: DateTime.now(),
      centerName: centerName,
      address: address,
      status: 'Pending',
    );
  }

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