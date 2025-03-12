import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_constants.dart';
import '../providers/app_provider.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final List<Widget>? actions;
  final bool showProfilePicture;

  const CustomAppBar({
    Key? key,
    required this.title,
    this.showBackButton = true,
    this.actions,
    this.showProfilePicture = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appProvider = Provider.of<AppProvider>(context);
    final currentUser = appProvider.currentUser;

    return AppBar(
      backgroundColor: AppConstants.primaryColor,
      elevation: 0,
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
          color: Colors.white,
        ),
      ),
      centerTitle: true,
      leading: showBackButton
          ? Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
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