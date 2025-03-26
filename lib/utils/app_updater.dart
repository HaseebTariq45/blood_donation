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

class AppUpdater {
  // Default version in case we can't get it from PackageInfo
  static String currentVersion = '1.0.0';
  static const String appName = 'BloodLine';
  
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
  
  // Google Drive direct download handling
  static String _getProperGoogleDriveUrl(String url) {
    if (url.isEmpty) return '';
    
    // Check if this is a Google Drive URL
    if (url.contains('drive.google.com') && url.contains('/d/')) {
      // Extract file ID
      String? fileId;
      
      // Format: https://drive.google.com/file/d/FILE_ID/view
      if (url.contains('/file/d/')) {
        final RegExp regExp = RegExp(r'/file/d/([^/]+)');
        final match = regExp.firstMatch(url);
        fileId = match?.group(1);
      } 
      // Format: https://drive.google.com/open?id=FILE_ID
      else if (url.contains('id=')) {
        final Uri uri = Uri.parse(url);
        fileId = uri.queryParameters['id'];
      }
      // Format: https://drive.google.com/uc?export=download&id=FILE_ID
      else if (url.contains('uc?') && url.contains('export=download')) {
        // This is already in the correct format, return as is
        return url;
      }
      
      if (fileId != null && fileId.isNotEmpty) {
        debugPrint('Extracted Google Drive file ID: $fileId');
        // For large files, use the export=download&confirm=t format
        // which is more reliable than the regular export=download
        return 'https://drive.google.com/uc?export=download&id=$fileId&confirm=t';
      }
    }
    
    // Not a Google Drive URL or couldn't parse, return original
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
        final apkFileId = data['apkFileId'] ?? '';
        
        // Construct the download URL if we have an apkFileId
        String finalDownloadUrl = downloadUrl.isNotEmpty 
            ? downloadUrl 
            : apkFileId.isNotEmpty 
                ? 'https://drive.google.com/uc?export=download&id=$apkFileId' 
                : '';
                
        // Make sure we have a proper download URL for Google Drive
        finalDownloadUrl = _getProperGoogleDriveUrl(finalDownloadUrl);
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
  
  // Check if a Google Drive file is large and requires confirmation
  static Future<String> _handleGoogleDriveConfirmation(String url) async {
    if (!url.contains('drive.google.com')) {
      return url; // Not a Google Drive URL
    }
    
    try {
      debugPrint('Checking if Google Drive file requires confirmation...');
      
      // Set browser-like headers to avoid being detected as a bot
      final headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
        'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
        'Accept-Language': 'en-US,en;q=0.9',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
        'Referer': 'https://drive.google.com/',
        'sec-ch-ua': '"Not_A Brand";v="8", "Chromium";v="120", "Google Chrome";v="120"',
        'sec-ch-ua-mobile': '?0',
        'sec-ch-ua-platform': '"Windows"',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'same-origin',
        'Upgrade-Insecure-Requests': '1',
      };
      
      // First request to check if we get a confirmation page
      final response = await http.get(Uri.parse(url), headers: headers);
      final body = response.body;
      
      // Debug the response
      debugPrint('Response status code: ${response.statusCode}');
      debugPrint('Response content type: ${response.headers['content-type']}');
      debugPrint('Response body length: ${body.length}');
      
      // Check if we received a confirmation page instead of the file
      if (body.contains('Virus scan warning') || 
          body.contains('Google Drive can\'t scan this file for viruses') ||
          body.contains('confirm=') ||
          body.contains('Download anyway') ||
          (response.headers['content-type']?.contains('text/html') ?? false)) {
        
        debugPrint('Google Drive confirmation page detected, extracting download link...');
        
        // Look for the direct download link - Method 1: Look for confirmation token
        final RegExp confirmRegex = RegExp(r'confirm=([^&"]+)');
        final match = confirmRegex.firstMatch(body);
        
        if (match != null && match.group(1) != null) {
          final confirmToken = match.group(1);
          debugPrint('Found confirmation token: $confirmToken');
          
          // Create a URL with the confirmation token
          if (url.contains('?')) {
            if (url.contains('confirm=')) {
              // Already has confirm, replace it
              final newUrl = url.replaceAll(RegExp(r'confirm=[^&]+'), 'confirm=$confirmToken');
              debugPrint('Replaced confirm token: $newUrl');
              return newUrl;
            } else {
              // Has other parameters, add confirm
              debugPrint('Adding confirm token: $url&confirm=$confirmToken');
              return '$url&confirm=$confirmToken';
            }
          } else {
            // No parameters yet
            debugPrint('Adding confirm token as first param: $url?confirm=$confirmToken');
            return '$url?confirm=$confirmToken';
          }
        }
        
        // Method 2: Look for the download button
        final downloadButtonRegex = RegExp(r'href="(/uc[^"]+)"\s+id="(downloadForm|download-button)"');
        final downloadButtonMatch = downloadButtonRegex.firstMatch(body);
        
        if (downloadButtonMatch != null && downloadButtonMatch.group(1) != null) {
          final downloadPath = downloadButtonMatch.group(1)!.replaceAll('&amp;', '&');
          final downloadUrl = 'https://drive.google.com${downloadPath}';
          debugPrint('Found download button link: $downloadUrl');
          return downloadUrl;
        }
        
        // Alternative pattern for download button with single quotes
        final downloadButtonRegex2 = RegExp(r"href='(/uc[^']+)'\s+id='(downloadForm|download-button)'");
        final downloadButtonMatch2 = downloadButtonRegex2.firstMatch(body);
        
        if (downloadButtonMatch2 != null && downloadButtonMatch2.group(1) != null) {
          final downloadPath = downloadButtonMatch2.group(1)!.replaceAll('&amp;', '&');
          final downloadUrl = 'https://drive.google.com${downloadPath}';
          debugPrint('Found download button link (alt): $downloadUrl');
          return downloadUrl;
        }
        
        // Method 3: Look for the "Download anyway" button link with double quotes
        final downloadAnywayRegex = RegExp(r'href="([^"]*\/uc\?[^"]*export=download[^"]*)"');
        final downloadAnywayMatch = downloadAnywayRegex.firstMatch(body);
        
        if (downloadAnywayMatch != null && downloadAnywayMatch.group(1) != null) {
          String downloadLink = downloadAnywayMatch.group(1)!.replaceAll('&amp;', '&');
          // If it's a relative URL, prepend the Google Drive domain
          if (downloadLink.startsWith('/')) {
            downloadLink = 'https://drive.google.com${downloadLink}';
          }
          debugPrint('Found "Download anyway" link: $downloadLink');
          return downloadLink;
        }
        
        // Alternative pattern for download anyway with single quotes
        final downloadAnywayRegex2 = RegExp(r"href='([^']*\/uc\?[^']*export=download[^']*)'");
        final downloadAnywayMatch2 = downloadAnywayRegex2.firstMatch(body);
        
        if (downloadAnywayMatch2 != null && downloadAnywayMatch2.group(1) != null) {
          String downloadLink = downloadAnywayMatch2.group(1)!.replaceAll('&amp;', '&');
          if (downloadLink.startsWith('/')) {
            downloadLink = 'https://drive.google.com${downloadLink}';
          }
          debugPrint('Found "Download anyway" link (alt): $downloadLink');
          return downloadLink;
        }
        
        // Method 4: Look for the form action with double quotes
        final formActionRegex = RegExp(r'action="(/uc\?[^"]+)"');
        final formActionMatch = formActionRegex.firstMatch(body);
        
        if (formActionMatch != null && formActionMatch.group(1) != null) {
          final formAction = 'https://drive.google.com${formActionMatch.group(1)!.replaceAll('&amp;', '&')}';
          debugPrint('Found form action: $formAction');
          return formAction;
        }
        
        // Alternative pattern for form action with single quotes
        final formActionRegex2 = RegExp(r"action='(/uc\?[^']+)'");
        final formActionMatch2 = formActionRegex2.firstMatch(body);
        
        if (formActionMatch2 != null && formActionMatch2.group(1) != null) {
          final formAction = 'https://drive.google.com${formActionMatch2.group(1)!.replaceAll('&amp;', '&')}';
          debugPrint('Found form action (alt): $formAction');
          return formAction;
        }
        
        // Method 5: If file ID is in URL, construct a forced download URL
        final RegExp fileIdRegex = RegExp(r'id=([^&]+)');
        final fileIdMatch = fileIdRegex.firstMatch(url);
        
        if (fileIdMatch != null && fileIdMatch.group(1) != null) {
          final fileId = fileIdMatch.group(1);
          final forceDownloadUrl = 'https://drive.google.com/uc?export=download&id=$fileId&confirm=t';
          debugPrint('Constructed forced download URL from file ID: $forceDownloadUrl');
          return forceDownloadUrl;
        }
        
        // If all extraction methods fail, add &confirm=t to the URL as a fallback
        if (!url.contains('confirm=')) {
          final fallbackUrl = url.contains('?') ? '$url&confirm=t' : '$url?confirm=t';
          debugPrint('Using fallback URL with confirm=t: $fallbackUrl');
          return fallbackUrl;
        }
      } else if (response.statusCode == 302 || response.statusCode == 303) {
        // Handle redirects
        final redirectUrl = response.headers['location'];
        if (redirectUrl != null && redirectUrl.isNotEmpty) {
          debugPrint('Following redirect to: $redirectUrl');
          return redirectUrl;
        }
      }
      
      // If we get here, no confirmation needed or couldn't parse
      debugPrint('No confirmation page detected or couldn\'t parse it');
      return url;
    } catch (e) {
      debugPrint('Error checking Google Drive confirmation: $e');
      return url; // Return original URL if anything fails
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
      if (url.isEmpty) {
        onError('Download URL is empty');
        return;
      }
      
      debugPrint('Starting download from URL: $url');
      isUpdateInProgress = true;
      
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        isUpdateInProgress = false;
        onError('Storage permission not granted');
        debugPrint('Storage permission denied');
        return;
      }
      
      // Get temporary directory for downloading
      final directory = await getExternalStorageDirectory() ?? await getTemporaryDirectory();
      final filePath = '${directory.path}/$appName-${DateTime.now().millisecondsSinceEpoch}.apk';
      debugPrint('File will be saved to: $filePath');
      
      try {
        // Handle Google Drive confirmation for large files
        String downloadUrl = url;
        
        // Only use the complex confirmation handling for Google Drive URLs
        if (url.contains('drive.google.com')) {
          debugPrint('Detected Google Drive URL, handling confirmation page...');
          downloadUrl = await _handleGoogleDriveConfirmation(url);
          
          if (downloadUrl != url) {
            debugPrint('Using updated Google Drive URL with confirmation: $downloadUrl');
          }
        }
        
        // Download the file with custom headers
        Map<String, String> headers = {};
        
        // Add browser-like headers for Google Drive to avoid bot detection
        if (downloadUrl.contains('drive.google.com')) {
          headers = {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36',
            'Accept': 'application/octet-stream, application/vnd.android.package-archive',
            'Accept-Language': 'en-US,en;q=0.9',
            'Accept-Encoding': 'gzip, deflate, br',
            'Referer': 'https://drive.google.com/',
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
          final file = File(filePath);
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
              await File('${directory.path}/error_response.html').writeAsString(await file.readAsString());
              debugPrint('Saved HTML response to ${directory.path}/error_response.html for debugging');
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
            
            // Installation handled differently based on platform
            if (Platform.isAndroid) {
              // On Android, open the APK for installation
              debugPrint('Download successful, proceeding to installation');
              onComplete(filePath);
            } else {
              // On iOS or other platforms, share the file
              debugPrint('Download successful, sharing file on non-Android platform');
              await Share.shareXFiles([XFile(filePath)], text: 'Install $appName update');
              onComplete('Update downloaded. Please install the shared file.');
            }
            
            isUpdateInProgress = false;
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
      final file = File(filePath);
      if (await file.exists()) {
        // Use Intent to open the APK file
        if (await canLaunchUrl(Uri.file(filePath))) {
          await launchUrl(Uri.file(filePath), mode: LaunchMode.externalApplication);
        } else {
          throw 'Could not launch $filePath';
        }
      } else {
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
      
      // For Google Drive URLs, ensure we have the proper parameters
      if (url.contains('drive.google.com')) {
        // Extract the file ID if present
        final RegExp fileIdRegex = RegExp(r'id=([^&]+)');
        final match = fileIdRegex.firstMatch(url);
        
        if (match != null && match.group(1) != null) {
          final fileId = match.group(1);
          // Force the mobile URL format which works better in browser
          url = 'https://drive.google.com/uc?export=download&id=$fileId&confirm=t';
          debugPrint('Using modified Google Drive URL: $url');
        } else if (!url.contains('confirm=')) {
          // Add confirm parameter if not present
          url = url.contains('?') ? '$url&confirm=t' : '$url?confirm=t';
          debugPrint('Added confirm parameter: $url');
        }
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
  static String getDirectDownloadUrl(String fileId) {
    if (fileId.isEmpty) return '';
    return 'https://drive.google.com/uc?export=download&id=$fileId&confirm=t';
  }
} 