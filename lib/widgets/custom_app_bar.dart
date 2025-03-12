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

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.showProfilePicture = true,
    this.translateTitle = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentUser = appProvider.currentUser;

    final displayTitle = translateTitle ? title.tr(context) : title;

    return AppBar(
      backgroundColor: Theme.of(context).brightness == Brightness.dark 
          ? Theme.of(context).appBarTheme.backgroundColor 
          : AppConstants.primaryColor,
      elevation: 0,
      title: Text(
        displayTitle,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Theme.of(context).brightness == Brightness.dark 
              ? Colors.white 
              : Colors.white,
        ),
      ),
      centerTitle: true,
      leading: showBackButton
          ? Container(
              margin: const EdgeInsets.all(8),
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
                  size: 18,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      actions: actions ??
          (showProfilePicture
              ? [
                  Padding(
                    padding: const EdgeInsets.only(right: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        // Navigate to profile screen
                        Navigator.pushNamed(context, '/profile');
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.white,
                        backgroundImage: currentUser.imageUrl.isNotEmpty
                            ? NetworkImage(currentUser.imageUrl)
                            : null,
                        child: currentUser.imageUrl.isEmpty
                            ? const Icon(
                                Icons.person,
                                color: AppConstants.primaryColor,
                                size: 16,
                              )
                            : null,
                      ),
                    ),
                  ),
                ]
              : null),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
} 