import 'package:flutter/material.dart';
import '../widgets/custom_app_bar.dart';
import '../constants/app_constants.dart';
import '../utils/localization/app_localization.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: 'terms_of_service'.tr(context),
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
                'terms_last_updated'.tr(context),
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),

              // Introduction
              _buildSectionTitle(context, 'terms_intro_title'),
              _buildParagraph(context, 'terms_intro_content'),
              const SizedBox(height: 16),

              // Eligibility
              _buildSectionTitle(context, 'terms_eligibility_title'),
              _buildParagraph(context, 'terms_eligibility_content'),
              _buildBulletPoints(context, [
                'terms_eligibility_point1',
                'terms_eligibility_point2',
                'terms_eligibility_point3',
                'terms_eligibility_point4',
              ]),
              const SizedBox(height: 16),

              // Account Responsibilities
              _buildSectionTitle(context, 'terms_account_title'),
              _buildParagraph(context, 'terms_account_content'),
              _buildBulletPoints(context, [
                'terms_account_point1',
                'terms_account_point2',
                'terms_account_point3',
                'terms_account_point4',
              ]),
              const SizedBox(height: 16),

              // Code of Conduct
              _buildSectionTitle(context, 'terms_conduct_title'),
              _buildParagraph(context, 'terms_conduct_content'),
              _buildBulletPoints(context, [
                'terms_conduct_point1',
                'terms_conduct_point2',
                'terms_conduct_point3',
                'terms_conduct_point4',
                'terms_conduct_point5',
              ]),
              const SizedBox(height: 16),

              // Blood Donation Rules
              _buildSectionTitle(context, 'terms_donation_title'),
              _buildParagraph(context, 'terms_donation_content'),
              _buildBulletPoints(context, [
                'terms_donation_point1',
                'terms_donation_point2',
                'terms_donation_point3',
                'terms_donation_point4',
              ]),
              const SizedBox(height: 16),

              // Intellectual Property
              _buildSectionTitle(context, 'terms_ip_title'),
              _buildParagraph(context, 'terms_ip_content'),
              const SizedBox(height: 16),

              // Limitation of Liability
              _buildSectionTitle(context, 'terms_liability_title'),
              _buildParagraph(context, 'terms_liability_content'),
              const SizedBox(height: 16),

              // Termination
              _buildSectionTitle(context, 'terms_termination_title'),
              _buildParagraph(context, 'terms_termination_content'),
              const SizedBox(height: 16),

              // Changes to Terms
              _buildSectionTitle(context, 'terms_changes_title'),
              _buildParagraph(context, 'terms_changes_content'),
              const SizedBox(height: 16),

              // Contact Information
              _buildSectionTitle(context, 'terms_contact_title'),
              _buildParagraph(context, 'terms_contact_content'),
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