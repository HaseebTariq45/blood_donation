import 'package:intl/intl.dart';

class BloodRequestModel {
  final String id;
  final String requesterId;
  final String requesterName;
  final String contactNumber;
  final String bloodType;
  final String location;
  final String urgency; // Normal, Urgent
  final DateTime requestDate;
  final String status; // Pending, Fulfilled, Cancelled
  final String notes;

  BloodRequestModel({
    required this.id,
    required this.requesterId,
    required this.requesterName,
    required this.contactNumber,
    required this.bloodType,
    required this.location,
    required this.requestDate,
    this.urgency = 'Normal',
    this.status = 'Pending',
    this.notes = '',
  });

  String get formattedDate => DateFormat('MMM dd, yyyy').format(requestDate);

  bool get isUrgent => urgency == 'Urgent';

  factory BloodRequestModel.dummy(int index) {
    final bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
    final urgencyTypes = ['Normal', 'Urgent'];
    final statusTypes = ['Pending', 'Fulfilled', 'Cancelled'];
    
    return BloodRequestModel(
      id: 'request_$index',
      requesterId: 'requester_$index',
      requesterName: 'Requester ${index + 1}',
      contactNumber: '+12345${index}7890',
      bloodType: bloodTypes[index % bloodTypes.length],
      location: 'Hospital ${index + 1}, City',
      requestDate: DateTime.now().subtract(Duration(days: index * 2)),
      urgency: urgencyTypes[index % 2],
      status: statusTypes[index % 3],
      notes: index % 2 == 0 ? 'Needed for surgery' : 'Regular requirement',
    );
  }

  static List<BloodRequestModel> getDummyList() {
    return List.generate(8, (index) => BloodRequestModel.dummy(index));
  }
} 