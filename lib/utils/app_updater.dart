import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Import for Android platform channel
import 'package:flutter/services.dart';

class AppUpdater {
  // Default version in case we can't get it from PackageInfo
  static String currentVersion = '1.0.0';
  static const String appName = 'BloodLine';
  
  // Platform channel for native code - use the correct applicationId from build.gradle
  static const platform = MethodChannel('com.codematesolution.bloodline/updates');
  
  // Firestore collection and document for app updates
  static const String updateCollection = 'app_updates';
  static const String updateDocument = 'latest_version';
  
  // Direct download link for APK on Google Drive (will be fetched from Firestore)
  static String latestApkUrl = '';
  
  // Indicates if an update is in progress
  static bool isUpdateInProgress = false;
  
  // Initialize by getting the current app version
  static Future<void> initialize() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      currentVersion = packageInfo.version;
    } catch (e) {
      // If there's an error, keep using the default version
    }
  }
  
  // Dropbox direct download handling
  static String _getProperDropboxUrl(String url) {
    if (url.isEmpty) return '';
    
    // Check if this is a Dropbox URL
    if (url.contains('dropbox.com')) {
      // Convert www.dropbox.com to dl.dropboxusercontent.com
      url = url.replaceAll('www.dropbox.com', 'dl.dropboxusercontent.com');
      
      // Remove the st parameter if present
      final uriObj = Uri.parse(url);
      final queryParams = Map<String, String>.from(uriObj.queryParameters);
      
      if (queryParams.containsKey('st')) {
        queryParams.remove('st');
      }
      
      // Set dl=1 to enable direct download
      queryParams['dl'] = '1';
      
      // Rebuild the URL with updated parameters
      final Uri newUri = Uri(
        scheme: uriObj.scheme,
        host: uriObj.host,
        path: uriObj.path,
        queryParameters: queryParams
      );
      
      return newUri.toString();
    }
    
    // Not a Dropbox URL, return original
    return url;
  }
  
  // Check for updates by comparing versions using Firestore
  static Future<Map<String, dynamic>> checkForUpdates() async {
    try {
      // Make sure we have the current version
      await initialize();
      
      // Access Firestore to get update information
      final firestoreInstance = FirebaseFirestore.instance;
      final DocumentSnapshot updateDoc = await firestoreInstance
          .collection(updateCollection)
          .doc(updateDocument)
          .get();
      
      if (updateDoc.exists) {
        final data = updateDoc.data() as Map<String, dynamic>;
        final latestVersion = data['latestVersion'] ?? '';
        final releaseNotes = data['releaseNotes'] ?? 'New features and bug fixes';
        final downloadUrl = data['downloadUrl'] ?? '';
        
        // Make sure we have a proper download URL for Dropbox
        String finalDownloadUrl = _getProperDropboxUrl(downloadUrl);
        debugPrint('Final download URL: $finalDownloadUrl');
        
        // Save the latest APK URL for later use
        latestApkUrl = finalDownloadUrl;
        
        // Compare versions
        final bool hasUpdate = _isNewerVersion(latestVersion, currentVersion);
        
        return {
          'hasUpdate': hasUpdate,
          'latestVersion': latestVersion,
          'currentVersion': currentVersion,
          'releaseNotes': releaseNotes,
          'downloadUrl': finalDownloadUrl,
        };
      } else {
        debugPrint('Update document not found in Firestore');
        // If we can't fetch update info, return no update available
        return {
          'hasUpdate': false,
          'latestVersion': '',
          'currentVersion': currentVersion,
          'releaseNotes': '',
          'downloadUrl': '',
        };
      }
    } catch (e) {
      // If any error occurs, return no update available
      debugPrint('Error checking for updates: $e');
      return {
        'hasUpdate': false,
        'latestVersion': '',
        'currentVersion': currentVersion,
        'releaseNotes': '',
        'downloadUrl': '',
      };
    }
  }
  
  // Helper to compare semantic versions
  static bool _isNewerVersion(String newVersion, String currentVersion) {
    if (newVersion.isEmpty) return false;
    
    try {
      List<int> newParts = newVersion.split('.').map((part) => int.parse(part)).toList();
      List<int> currentParts = currentVersion.split('.').map((part) => int.parse(part)).toList();
      
      // Ensure lists are of equal length
      while (newParts.length < 3) newParts.add(0);
      while (currentParts.length < 3) currentParts.add(0);
      
      // Compare major version
      if (newParts[0] > currentParts[0]) return true;
      if (newParts[0] < currentParts[0]) return false;
      
      // Compare minor version
      if (newParts[1] > currentParts[1]) return true;
      if (newParts[1] < currentParts[1]) return false;
      
      // Compare patch version
      return newParts[2] > currentParts[2];
    } catch (e) {
      debugPrint('Error comparing versions: $e');
      return false;
    }
  }
  
  // Download and install the update
  static Future<void> downloadUpdate(
    String url, 
    Function(double) onProgress, 
    Function(String) onComplete,
    Function(String) onError
  ) async {
    try {
      debugPrint('Starting download from URL: $url');
      isUpdateInProgress = true;
      
      // Request storage permission for saving the APK
      final permissionStatus = await Permission.storage.request();
      if (permissionStatus.isDenied) {
        isUpdateInProgress = false;
        onError('Storage permission denied. Please grant permission to download updates.');
        return;
      }
      
      // Create a temporary file in app's cache to download first
      final tempDir = await getTemporaryDirectory();
      final fileName = 'bloodline_update.apk';
      final tempFilePath = '${tempDir.path}/$fileName';
      
      debugPrint('Will save initially to temporary path: $tempFilePath');
      
      try {
        // Handle Dropbox URL
        String downloadUrl = url;
        
        // Make sure we have a proper download URL for Dropbox
        if (url.contains('dropbox.com')) {
          debugPrint('Detected Dropbox URL, ensuring direct download...');
          downloadUrl = _getProperDropboxUrl(url);
          
          if (downloadUrl != url) {
            debugPrint('Using updated Dropbox URL: $downloadUrl');
          }
        }
        
        // Download the file with custom headers
        Map<String, String> headers = {};
        
        // Add browser-like headers for Dropbox to avoid any issues
        if (downloadUrl.contains('dropbox.com')) {
          headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/octet-stream, application/vnd.android.package-archive',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
          };
          
          // Try a HEAD request first to check if we need to handle any redirects
          debugPrint('Sending HEAD request to check for redirects...');
          final redirectCheck = await http.head(Uri.parse(downloadUrl), headers: headers);
          debugPrint('HEAD response status: ${redirectCheck.statusCode}');
          
          if (redirectCheck.statusCode == 302 || redirectCheck.statusCode == 303) {
            final redirectUrl = redirectCheck.headers['location'];
            if (redirectUrl != null && redirectUrl.isNotEmpty) {
              downloadUrl = redirectUrl;
              debugPrint('Following redirect detected in HEAD request: $downloadUrl');
            }
          }
        }
        
        // Create a client that allows handling redirects manually if needed
        final client = http.Client();
        
        try {
          debugPrint('Sending download request to: $downloadUrl');
          debugPrint('Using headers: $headers');
          
          // Use http.Client().send() to get StreamedResponse for progress tracking
          final request = http.Request('GET', Uri.parse(downloadUrl));
          request.headers.addAll(headers);
          
          debugPrint('Sending HTTP request for file download...');
          final response = await client.send(request);
          
          // Log response details
          debugPrint('Response status code: ${response.statusCode}');
          debugPrint('Response headers: ${response.headers}');
          
          if (response.statusCode != 200) {
            final errorMsg = 'Download failed with status code: ${response.statusCode}';
            debugPrint(errorMsg);
            isUpdateInProgress = false;
            onError(errorMsg);
            return;
          }
          
          // Check content type - if it's HTML, we're likely getting an error page
          final contentType = response.headers['content-type'] ?? '';
          debugPrint('Content-Type: $contentType');
          
          if (contentType.contains('text/html') || contentType.contains('text/plain')) {
            debugPrint('Warning: Received content-type $contentType instead of application/octet-stream or application/vnd.android.package-archive');
            // Continue but monitor the download to check file type
          }
          
          final contentLength = response.contentLength ?? 0;
          debugPrint('Content length: $contentLength bytes');
          
          if (contentLength <= 0) {
            debugPrint('Warning: Content length is zero or not provided');
          }
          
          // Create the file and open a sink for writing
          final file = File(tempFilePath);
          final sink = file.openWrite();
          int receivedBytes = 0;
          
          debugPrint('Starting to receive file data...');
          await response.stream.forEach((chunk) {
            sink.add(chunk);
            receivedBytes += chunk.length;
            
            if (receivedBytes % 1000000 == 0) { // Log every ~1MB
              debugPrint('Received $receivedBytes / $contentLength bytes');
            }
            
            if (contentLength > 0) {
              final progress = receivedBytes / contentLength;
              onProgress(progress);
            } else {
              // If content length is unknown, show indeterminate progress
              onProgress(-1);
            }
          });
          
          await sink.flush();
          await sink.close();
          
          // Verify the file was created and has content
          if (await file.exists()) {
            final fileSize = await file.length();
            debugPrint('File download complete. Size: $fileSize bytes');
            
            if (fileSize == 0) {
              final errorMsg = 'Downloaded file is empty (0 bytes)';
              debugPrint(errorMsg);
              isUpdateInProgress = false;
              onError(errorMsg);
              return;
            }
            
            // Check if it's actually an APK and not an HTML page
            final List<int> bytes = await file.openRead(0, min(50, fileSize.toInt())).fold<List<int>>(
              [],
              (List<int> previous, List<int> element) => previous..addAll(element),
            );
            final Uint8List firstBytes = Uint8List.fromList(bytes);
            
            // APK files start with the ZIP file signature (PK..)
            final bool isZipFile = firstBytes.length >= 4 && 
                                  firstBytes[0] == 0x50 && // P
                                  firstBytes[1] == 0x4B && // K
                                  firstBytes[2] == 0x03 && 
                                  firstBytes[3] == 0x04;
            
            // Log the first few bytes for debugging
            debugPrint('First 4 bytes of file: [${firstBytes.take(4).map((b) => '0x${b.toRadixString(16).padLeft(2, '0')}').join(', ')}]');
            
            // Check if the file starts with HTML tags
            final String fileStart = String.fromCharCodes(firstBytes);
            debugPrint('File starts with: ${fileStart.substring(0, min(30, fileStart.length))}...');
            
            if (fileStart.contains('<!DOCTYPE html>') || fileStart.contains('<html')) {
              final errorMsg = 'Downloaded file is HTML, not an APK. Received a webpage instead of the APK file.';
              debugPrint(errorMsg);
              // Save the HTML content for debugging
              await File('${file.parent.path}/error_response.html').writeAsString(await file.readAsString());
              debugPrint('Saved HTML response to ${file.parent.path}/error_response.html for debugging');
              isUpdateInProgress = false;
              onError(errorMsg);
              return;
            }
            
            if (!isZipFile) {
              final errorMsg = 'Downloaded file is not a valid APK (ZIP) file.';
              debugPrint(errorMsg);
              isUpdateInProgress = false;
              onError(errorMsg);
              return;
            }
            
            debugPrint('APK file downloaded successfully and validated');
            
            // Now try to save to the BloodLine folder using native platform methods
            String finalPath = tempFilePath;
            
            if (Platform.isAndroid) {
              try {
                // First try to create the BloodLine folder using platform channel
                final String? bloodLineFolderPath = await platform.invokeMethod('createBloodLineFolder');
                
                if (bloodLineFolderPath != null && bloodLineFolderPath.isNotEmpty) {
                  debugPrint('BloodLine folder created: $bloodLineFolderPath');
                  
                  // Try to save the file to BloodLine folder
                  final String? bloodLinePath = await platform.invokeMethod(
                    'saveToBloodLine',
                    {
                      'sourcePath': tempFilePath,
                      'fileName': fileName,
                    }
                  );
                  
                  if (bloodLinePath != null && bloodLinePath.isNotEmpty) {
                    debugPrint('Successfully saved to BloodLine folder: $bloodLinePath');
                    finalPath = bloodLinePath;
                  }
                }
              } catch (e) {
                debugPrint('Error using native BloodLine folder: $e');
                // Continue with fallback approaches
              }
              
              // If BloodLine folder attempt failed, try Downloads folder
              if (finalPath == tempFilePath) {
                try {
                  final String? downloadsPath = await platform.invokeMethod(
                    'saveToDownloads',
                    {
                      'sourcePath': tempFilePath,
                      'fileName': fileName,
                    }
                  );
                  
                  if (downloadsPath != null && downloadsPath.isNotEmpty) {
                    debugPrint('Successfully saved to Downloads folder: $downloadsPath');
                    finalPath = downloadsPath;
                  }
                } catch (e) {
                  debugPrint('Error saving to Downloads folder: $e');
                  // Continue with temporary file
                }
              }
            }
            
            debugPrint('Final APK path for installation: $finalPath');
            
            // Installation handled differently based on platform
            if (Platform.isAndroid) {
              // On Android, directly install the APK using the installApk method
              debugPrint('Proceeding to APK installation');
              isUpdateInProgress = false;
              try {
                // Share file for installation - this is the most reliable approach
                final result = await Share.shareXFiles(
                  [XFile(finalPath)], 
                  text: 'Install $appName update',
                  subject: 'Install $appName',
                  sharePositionOrigin: null,
                );
                debugPrint('Share result: $result');
                
                // Determine the appropriate message based on the file path
                String locationMsg;
                if (finalPath.contains('BloodLine')) {
                  locationMsg = 'Downloads/BloodLine folder';
                } else if (finalPath.contains('Download')) {
                  locationMsg = 'Downloads folder';
                } else {
                  locationMsg = 'temporary location';
                }
                
                onComplete('Update downloaded to the $locationMsg. Please select "Package Installer" to install the app.');
                
                // After sharing, try to directly install as backup
                Future.delayed(Duration(seconds: 2), () async {
                  try {
                    await installApk(finalPath);
                    debugPrint('Delayed installation started directly');
                  } catch (e) {
                    debugPrint('Could not start direct installation: $e');
                    // It's OK if this fails since we already shared the file
                  }
                });
              } catch (e) {
                // If sharing fails, try direct installation
                debugPrint('Error sharing APK: $e. Trying direct installation.');
                try {
                  await installApk(finalPath);
                  onComplete('Update download completed. Installation started.');
                } catch (e2) {
                  // If installation fails, still mark as complete but show error
                  debugPrint('Error during APK installation: $e2');
                  
                  // Determine the appropriate message based on the file path
                  String locationMsg;
                  if (finalPath.contains('BloodLine')) {
                    locationMsg = 'Downloads/BloodLine folder';
                  } else if (finalPath.contains('Download')) {
                    locationMsg = 'Downloads folder';
                  } else {
                    locationMsg = file.parent.path;
                  }
                  
                  onComplete('Update downloaded to: $locationMsg\nPlease install manually using your file manager.');
                }
              }
            } else {
              // On iOS or other platforms, share the file
              debugPrint('Download successful, sharing file on non-Android platform');
              await Share.shareXFiles([XFile(finalPath)], text: 'Install $appName update');
              isUpdateInProgress = false;
              onComplete('Update downloaded. Please install the shared file.');
            }
          } else {
            final errorMsg = 'File was not created';
            debugPrint(errorMsg);
            isUpdateInProgress = false;
            onError(errorMsg);
            return;
          }
        } finally {
          client.close();
        }
      } catch (e) {
        final errorMsg = 'Network error during download: $e';
        debugPrint(errorMsg);
        isUpdateInProgress = false;
        onError(errorMsg);
      }
    } catch (e) {
      final errorMsg = 'Error downloading update: $e';
      debugPrint(errorMsg);
      isUpdateInProgress = false;
      onError(errorMsg);
    }
  }
  
  // Install the APK (Android only)
  static Future<void> installApk(String filePath) async {
    try {
      debugPrint('Installing APK from: $filePath');
      final file = File(filePath);
      
      if (await file.exists()) {
        debugPrint('APK file exists, proceeding with installation');
        
        // For Android, we need to use multiple approaches
        if (Platform.isAndroid) {
          // Try using direct intent with MIME type
          final uri = Uri.file(filePath);
          final Map<String, dynamic> intentParams = {
            'action': 'android.intent.action.VIEW',
            'data': uri.toString(),
            'flags': '268435456', // FLAG_ACTIVITY_NEW_TASK
            'type': 'application/vnd.android.package-archive',
          };
          
          debugPrint('Attempting direct installation with intent params: $intentParams');
          
          // Create a URI with intent parameters
          final uriWithParams = Uri.https('', '', intentParams);
          
          if (await canLaunchUrl(uri)) {
            debugPrint('Launching with file URI...');
            await launchUrl(
              uri,
              mode: LaunchMode.externalApplication,
            );
            return;
          }
          
          // Second approach: try using a direct content:// URI approach
          try {
            // Some devices require removing the initial slash
            final String adjustedPath = filePath.startsWith('/') 
                ? filePath.substring(1) 
                : filePath;
            
            // Create a simple content URI
            debugPrint('Trying content URI approach...');
            final contentUri = Uri.parse('content://$adjustedPath');
            
            if (await canLaunchUrl(contentUri)) {
              await launchUrl(
                contentUri, 
                mode: LaunchMode.externalApplication,
              );
              debugPrint('Launched with content URI');
              return;
            }
          } catch (e) {
            debugPrint('Error with content URI approach: $e');
          }
          
          // Final fallback: Try to open file with default app selector
          try {
            debugPrint('Trying generic file opener...');
            await launchUrl(
              Uri.file(filePath),
              mode: LaunchMode.platformDefault,
            );
            return;
          } catch (e) {
            debugPrint('Failed to open file with default app selector: $e');
          }
          
          throw 'All installation methods failed. Downloaded APK is at: $filePath';
        } else {
          // For other platforms
          if (await canLaunchUrl(Uri.file(filePath))) {
            await launchUrl(Uri.file(filePath), mode: LaunchMode.externalApplication);
            debugPrint('File opened for installation');
          } else {
            throw 'Could not launch $filePath';
          }
        }
      } else {
        debugPrint('APK file not found at: $filePath');
        throw 'APK file not found';
      }
    } catch (e) {
      debugPrint('Error installing APK: $e');
      throw 'Error installing APK: $e';
    }
  }
  
  // For testing: Direct URL download method
  static Future<Map<String, dynamic>> useDirectApkUrl(String directApkUrl, String latestVersion) async {
    await initialize();
    
    final bool hasUpdate = _isNewerVersion(latestVersion, currentVersion);
    latestApkUrl = directApkUrl;
    
    return {
      'hasUpdate': hasUpdate,
      'latestVersion': latestVersion,
      'currentVersion': currentVersion,
      'releaseNotes': 'Update to the latest version of $appName',
      'downloadUrl': directApkUrl,
    };
  }
  
  // Try to download larger files using external browser
  static Future<bool> downloadWithBrowser(String url) async {
    try {
      debugPrint('Trying to download with external browser: $url');
      
      // For Dropbox URLs, ensure we have the direct download link
      if (url.contains('dropbox.com')) {
        url = _getProperDropboxUrl(url);
        debugPrint('Using modified Dropbox URL: $url');
      }
      
      // Launch URL in external browser
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        debugPrint('Successfully launched browser for download');
        return true;
      } else {
        debugPrint('Could not launch URL: $url');
        return false;
      }
    } catch (e) {
      debugPrint('Error launching browser for download: $e');
      return false;
    }
  }
  
  // Get a direct download URL for the APK
  static String getDirectDownloadUrl(String url) {
    if (url.isEmpty) return '';
    return _getProperDropboxUrl(url);
  }
} 