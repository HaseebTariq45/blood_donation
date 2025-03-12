import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../utils/localization/app_localization.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool showProfilePicture;
  final bool translateTitle;
  final double? height;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.showProfilePicture = true,
    this.translateTitle = true,
    this.height,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentUser = appProvider.currentUser;

    // Get screen dimensions for responsive sizing
    final Size screenSize = MediaQuery.of(context).size;
    final double screenWidth = screenSize.width;
    
    // Determine if we're on a small screen
    final bool isSmallScreen = screenWidth < 360;
    
    // Calculate responsive sizes
    final double titleFontSize = isSmallScreen ? 16.0 : 18.0;
    final double backIconSize = isSmallScreen ? 16.0 : 18.0;
    final double profileIconSize = isSmallScreen ? 14.0 : 16.0;
    final double profileAvatarRadius = isSmallScreen ? 14.0 : 16.0;
    final double backButtonMargin = isSmallScreen ? 6.0 : 8.0;
    final double profilePadding = isSmallScreen ? 12.0 : 16.0;

    final displayTitle = translateTitle ? title.tr(context) : title;

    return AppBar(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? Theme.of(context).appBarTheme.backgroundColor 
          : AppConstants.primaryColor,
      elevation: 0,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          displayTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: titleFontSize,
            color: Theme.of(context).brightness == Brightness.dark 
                ? Colors.white 
                : Colors.white,
          ),
        ),
      ),
      centerTitle: true,
      leading: showBackButton
          ? Container(
              margin: EdgeInsets.all(backButtonMargin),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark 
                    ? Colors.white.withOpacity(0.1)
                    : Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: Icon(
                  Icons.arrow_back_ios,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? Colors.white
                      : Colors.white,
                  size: backIconSize,
                ),
                padding: EdgeInsets.zero,
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      actions: actions ??
          (showProfilePicture
              ? [
                  Padding(
                    padding: EdgeInsets.only(right: profilePadding),
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to profile screen
                        Navigator.pushNamed(context, '/profile');
                      },
                      child: CircleAvatar(
                        radius: profileAvatarRadius,
                        backgroundColor: Colors.white,
                        backgroundImage: currentUser.imageUrl.isNotEmpty
                            ? NetworkImage(currentUser.imageUrl)
                            : null,
                        child: currentUser.imageUrl.isEmpty
                            ? Icon(
                                Icons.person,
                                color: AppConstants.primaryColor,
                                size: profileIconSize,
                              )
                            : null,
                      ),
                    ),
                  ),
                ]
              : null),
      toolbarHeight: height ?? (isSmallScreen ? kToolbarHeight * 0.9 : kToolbarHeight),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height ?? kToolbarHeight);
} 