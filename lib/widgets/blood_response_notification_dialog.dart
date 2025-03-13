import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/theme_helper.dart';

class BloodResponseNotificationDialog extends StatelessWidget {
  final String responderName;
  final String responderPhone;
  final String bloodType;
  final VoidCallback onViewRequest;
  
  const BloodResponseNotificationDialog({
    Key? key,
    required this.responderName,
    required this.responderPhone,
    required this.bloodType,
    required this.onViewRequest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: _buildDialogContent(context),
    );
  }
  
  Widget _buildDialogContent(BuildContext context) {
    return Stack(
      children: [
        // Main container
        Container(
          padding: const EdgeInsets.only(
            top: 65,
            bottom: 20,
            left: 20,
            right: 20,
          ),
          margin: const EdgeInsets.only(top: 45),
          decoration: BoxDecoration(
            shape: BoxShape.rectangle,
            color: context.cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                offset: const Offset(0, 10),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Blood Donation Response',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: context.textColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              Text(
                '$responderName has responded to your blood request',
                style: TextStyle(
                  fontSize: 16,
                  color: context.textColor,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              // Responder details card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? Colors.grey[850] : const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: context.isDarkMode ? Colors.grey[800]! : Colors.grey[300]!,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildInfoRow(
                      context: context,
                      icon: Icons.person,
                      title: 'Responder',
                      value: responderName,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context: context,
                      icon: Icons.bloodtype,
                      title: 'Blood Type',
                      value: bloodType,
                      color: AppConstants.primaryColor,
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow(
                      context: context,
                      icon: Icons.phone,
                      title: 'Phone Number',
                      value: responderPhone,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: AppConstants.primaryColor),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'DISMISS',
                        style: TextStyle(
                          color: AppConstants.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onViewRequest();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'VIEW DETAILS',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Top circular avatar
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: CircleAvatar(
            backgroundColor: AppConstants.primaryColor,
            radius: 45,
            child: Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppConstants.primaryColor,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.volunteer_activism,
                color: AppConstants.primaryColor,
                size: 40,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildInfoRow({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: context.secondaryTextColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: context.textColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
} 