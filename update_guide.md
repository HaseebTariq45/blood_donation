# App Update System - Google Drive Setup Guide

This guide explains how to set up the in-app update system using Google Drive.

## Step 1: Create and Upload the JSON File

1. Create a file named `update_info.json` with the following structure:
   ```json
   {
     "latestVersion": "1.1.0",
     "downloadUrl": "https://drive.google.com/uc?export=download&id=YOUR_APK_FILE_ID",
     "releaseNotes": "What's new in version 1.1.0:\n\n• New update feature added\n• Splash screen redesigned\n• Bug fixes and performance improvements"
   }
   ```

2. Upload this file to Google Drive (make sure it's publicly accessible)
3. Right-click on the file in Google Drive and select "Get link"
4. Click "Anyone with the link" to make it publicly accessible
5. Copy the link - it will look like: `https://drive.google.com/file/d/FILE_ID/view?usp=sharing`
6. Extract the `FILE_ID` from the link

## Step 2: Configure the App Updater

1. In `lib/utils/app_updater.dart`, update the `updateInfoUrl` constant:
   ```dart
   static const String updateInfoUrl = 'https://drive.google.com/uc?export=download&id=YOUR_JSON_FILE_ID';
   ```
   Replace `YOUR_JSON_FILE_ID` with the File ID you extracted from the JSON file link.

## Step 3: Upload Your APK File

1. Build your APK file with the new version number:
   ```
   flutter build apk --release
   ```
2. Upload the APK to Google Drive (make sure it's publicly accessible)
3. Right-click on the APK file and select "Get link"
4. Click "Anyone with the link" to make it publicly accessible
5. Copy the link and extract the File ID
6. Update your `update_info.json` file with the new APK File ID:
   ```json
   "downloadUrl": "https://drive.google.com/uc?export=download&id=YOUR_APK_FILE_ID"
   ```

## Step 4: Testing Updates

You can test the update system in two ways:

### Method 1: Using the JSON file (Production Approach)

1. Make sure your `updateInfoUrl` in `AppUpdater` points to the JSON file on Google Drive
2. Use the `checkForUpdates()` method in `AppProvider` without modification

### Method 2: Direct APK URL (Testing Approach)

In `lib/providers/app_provider.dart`, uncomment and use the direct URL method:

```dart
// Method 2: Using a direct APK URL (easier for testing)
final updateInfo = await AppUpdater.useDirectApkUrl(
  "https://drive.google.com/uc?export=download&id=YOUR_APK_FILE_ID",
  "1.1.0"
);
```

## Important Notes

1. **Version Numbers**: Always increment the version number in the JSON file when uploading a new APK.
2. **Drive Limits**: Google Drive has download limits. For production apps with many users, consider using a more robust solution.
3. **Large Files**: If APK is large (>100MB), users might face timeouts. Consider using Firebase App Distribution for more reliable distribution.

## Troubleshooting

- **Download Errors**: Ensure both files are publicly accessible on Google Drive
- **Installation Issues**: Check that all required Android permissions are properly set up
- **Update Not Showing**: Make sure the version in JSON is higher than the app's current version 