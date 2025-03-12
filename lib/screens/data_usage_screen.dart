import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:io' show Platform;
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../models/data_usage_model.dart';
import '../utils/theme_helper.dart';
import '../widgets/custom_app_bar.dart';
import '../services/service_locator.dart';

class DataUsageScreen extends StatefulWidget {
  const DataUsageScreen({Key? key}) : super(key: key);

  @override
  State<DataUsageScreen> createState() => _DataUsageScreenState();
}

class _DataUsageScreenState extends State<DataUsageScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshDataUsage();
    });
  }
  
  Future<void> _refreshDataUsage() async {
    await serviceLocator.networkTracker.refreshDataUsage();
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final dataUsage = appProvider.dataUsage;
    final isDarkMode = context.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: CustomAppBar(
        title: 'Data Usage',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              // Show loading indicator
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Refreshing data usage statistics...'),
                  duration: Duration(milliseconds: 500),
                ),
              );
              await _refreshDataUsage();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTotalUsageCard(context, dataUsage),
            const SizedBox(height: 20),
            _buildUsageBreakdown(context, dataUsage),
            const SizedBox(height: 20),
            _buildResetButton(context, appProvider),
            const SizedBox(height: 20),
            _buildDataUsageInfo(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalUsageCard(BuildContext context, DataUsageModel dataUsage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black12
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Total Data Used',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            DataUsageModel.formatBytes(dataUsage.totalBytes),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Since ${dataUsage.lastReset.day}/${dataUsage.lastReset.month}/${dataUsage.lastReset.year}',
            style: TextStyle(
              fontSize: 14,
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsageBreakdown(BuildContext context, DataUsageModel dataUsage) {
    final totalBytes = dataUsage.totalBytes.toDouble();
    final wifiBytes = dataUsage.wifiBytes.toDouble();
    final mobileBytes = dataUsage.mobileBytes.toDouble();
    
    // Ensure we don't divide by zero
    final wifiPercentage = totalBytes > 0 ? (wifiBytes / totalBytes * 100) : 0.0;
    final mobilePercentage = totalBytes > 0 ? (mobileBytes / totalBytes * 100) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: context.isDarkMode
                ? Colors.black12
                : Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Usage Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 20),
          
          // WiFi usage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.wifi,
                    color: Colors.blue,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'WiFi',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
              Text(
                DataUsageModel.formatBytes(dataUsage.wifiBytes),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: wifiPercentage / 100,
              minHeight: 10,
              backgroundColor: Colors.blue.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${wifiPercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: context.secondaryTextColor,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Mobile data usage
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.signal_cellular_alt,
                    color: Colors.orange,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Mobile Data',
                    style: TextStyle(
                      fontSize: 16,
                      color: context.textColor,
                    ),
                  ),
                ],
              ),
              Text(
                DataUsageModel.formatBytes(dataUsage.mobileBytes),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: mobilePercentage / 100,
              minHeight: 10,
              backgroundColor: Colors.orange.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${mobilePercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              color: context.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, AppProvider appProvider) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          _showResetConfirmationDialog(context, appProvider);
        },
        icon: const Icon(Icons.refresh),
        label: const Text('Reset Data Usage Statistics'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
        ),
      ),
    );
  }

  Widget _buildDataUsageInfo(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: context.isDarkMode
              ? Colors.grey.shade800
              : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About Data Usage Tracking',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This screen shows the approximate amount of data used by the app since the last reset. Data is tracked for both WiFi and mobile connections.',
            style: TextStyle(
              fontSize: 14,
              color: context.secondaryTextColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Note:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: context.textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '• Data usage is tracked only while the app is running\n• Values are approximate and may differ from actual network usage\n• Data is tracked locally and not shared with anyone',
            style: TextStyle(
              fontSize: 14,
              color: context.secondaryTextColor,
            ),
          ),
          if (_isPlatformWithLimitedConnectivityDetection()) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.amber,
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    color: Colors.amber,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'On ${_getPlatformName()}, connectivity detection is limited. All traffic is categorized as WiFi.',
                      style: TextStyle(
                        fontSize: 14,
                        color: context.textColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showResetConfirmationDialog(BuildContext context, AppProvider appProvider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: context.cardColor,
          title: Text(
            'Reset Data Usage',
            style: TextStyle(color: context.textColor),
          ),
          content: Text(
            'Are you sure you want to reset all data usage statistics? This action cannot be undone.',
            style: TextStyle(color: context.secondaryTextColor),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                appProvider.resetDataUsage();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Data usage statistics have been reset'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  bool _isPlatformWithLimitedConnectivityDetection() {
    // Desktop platforms (except macOS) and web have limited connectivity detection
    if (kIsWeb) return true;
    
    try {
      return Platform.isWindows || Platform.isLinux;
    } catch (e) {
      // If Platform is not available, assume limited detection
      return true;
    }
  }
  
  String _getPlatformName() {
    if (kIsWeb) return 'Web';
    
    try {
      if (Platform.isWindows) return 'Windows';
      if (Platform.isLinux) return 'Linux';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isFuchsia) return 'Fuchsia';
      return 'this platform';
    } catch (e) {
      return 'this platform';
    }
  }
} 