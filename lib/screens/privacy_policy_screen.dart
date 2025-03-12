import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../constants/app_constants.dart';
import '../utils/localization/app_localization.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'privacy_policy'.tr(context),
        showBackButton: true,
        showProfilePicture: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.paddingM),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Last Updated
              Text(
                'privacy_last_updated'.tr(context),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Introduction
              _buildSectionTitle(context, 'privacy_intro_title'),
              _buildParagraph(context, 'privacy_intro_content'),
              const SizedBox(height: 16),

              // Information We Collect
              _buildSectionTitle(context, 'privacy_collect_title'),
              _buildParagraph(context, 'privacy_collect_content'),
              
              // Personal Information
              _buildSubSectionTitle(context, 'privacy_personal_title'),
              _buildBulletPoints(context, [
                'privacy_personal_point1',
                'privacy_personal_point2',
                'privacy_personal_point3',
                'privacy_personal_point4',
                'privacy_personal_point5',
              ]),
              
              // Health Information
              _buildSubSectionTitle(context, 'privacy_health_title'),
              _buildBulletPoints(context, [
                'privacy_health_point1',
                'privacy_health_point2',
                'privacy_health_point3',
                'privacy_health_point4',
              ]),
              
              // Usage Information
              _buildSubSectionTitle(context, 'privacy_usage_title'),
              _buildBulletPoints(context, [
                'privacy_usage_point1',
                'privacy_usage_point2',
                'privacy_usage_point3',
              ]),
              const SizedBox(height: 16),

              // How We Use Your Information
              _buildSectionTitle(context, 'privacy_use_title'),
              _buildParagraph(context, 'privacy_use_content'),
              _buildBulletPoints(context, [
                'privacy_use_point1',
                'privacy_use_point2',
                'privacy_use_point3',
                'privacy_use_point4',
                'privacy_use_point5',
                'privacy_use_point6',
              ]),
              const SizedBox(height: 16),

              // Sharing Your Information
              _buildSectionTitle(context, 'privacy_share_title'),
              _buildParagraph(context, 'privacy_share_content'),
              _buildBulletPoints(context, [
                'privacy_share_point1',
                'privacy_share_point2',
                'privacy_share_point3',
                'privacy_share_point4',
              ]),
              const SizedBox(height: 16),

              // Data Security
              _buildSectionTitle(context, 'privacy_security_title'),
              _buildParagraph(context, 'privacy_security_content'),
              _buildBulletPoints(context, [
                'privacy_security_point1',
                'privacy_security_point2',
                'privacy_security_point3',
              ]),
              const SizedBox(height: 16),

              // Data Retention
              _buildSectionTitle(context, 'privacy_retention_title'),
              _buildParagraph(context, 'privacy_retention_content'),
              const SizedBox(height: 16),

              // Your Rights
              _buildSectionTitle(context, 'privacy_rights_title'),
              _buildParagraph(context, 'privacy_rights_content'),
              _buildBulletPoints(context, [
                'privacy_rights_point1',
                'privacy_rights_point2',
                'privacy_rights_point3',
                'privacy_rights_point4',
                'privacy_rights_point5',
              ]),
              const SizedBox(height: 16),

              // Children's Privacy
              _buildSectionTitle(context, 'privacy_children_title'),
              _buildParagraph(context, 'privacy_children_content'),
              const SizedBox(height: 16),

              // Changes to Privacy Policy
              _buildSectionTitle(context, 'privacy_changes_title'),
              _buildParagraph(context, 'privacy_changes_content'),
              const SizedBox(height: 16),

              // Contact Information
              _buildSectionTitle(context, 'privacy_contact_title'),
              _buildParagraph(context, 'privacy_contact_content'),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        key.tr(context),
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: AppConstants.primaryColor,
        ),
      ),
    );
  }

  Widget _buildSubSectionTitle(BuildContext context, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
      child: Text(
        key.tr(context),
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppConstants.darkTextColor,
        ),
      ),
    );
  }

  Widget _buildParagraph(BuildContext context, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        key.tr(context),
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBulletPoints(BuildContext context, List<String> points) {
    return Padding(
      padding: const EdgeInsets.only(left: 16.0, top: 8.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: points.map((point) => _buildBulletPoint(context, point)).toList(),
      ),
    );
  }

  Widget _buildBulletPoint(BuildContext context, String key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppConstants.primaryColor,
            ),
          ),
          Expanded(
            child: Text(
              key.tr(context),
              style: const TextStyle(
                fontSize: 15,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
} 