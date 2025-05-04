import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tene/providers/providers.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tene/screens/phone_link_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  @override
  void initState() {
    super.initState();

    // Schedule this after the frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncPhoneNumber();
    });
  }

  void _syncPhoneNumber() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser?.phoneNumber != null) {
      final userProfile = ref.read(userProfileProvider);

      // Check if the phone number in Firebase Auth is different from the one in userProfile
      if (userProfile['phoneNumber'] != currentUser!.phoneNumber) {
        final updatedProfile = Map<String, dynamic>.from(userProfile);
        updatedProfile['phoneNumber'] = currentUser.phoneNumber;
        ref.read(userProfileProvider.notifier).state = updatedProfile;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final moodData = ref.watch(currentMoodDataProvider);
    final userProfile = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: moodData.primaryColor,
        elevation: 0,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [moodData.primaryColor, moodData.secondaryColor.withOpacity(0.7)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Calculate responsive dimensions
              final maxHeight = constraints.maxHeight;
              final maxWidth = constraints.maxWidth;

              // Calculate avatar size based on screen width
              final avatarSize = maxWidth * 0.25;

              // Calculate font sizes based on screen width
              final titleFontSize = maxWidth * 0.06;
              final subtitleFontSize = maxWidth * 0.038;
              final bodyFontSize = maxWidth * 0.035;

              // Calculate button height based on screen height
              final buttonHeight = maxHeight * 0.07;

              // Calculate spacings based on screen height
              final verticalSpacing = maxHeight * 0.02;
              final sectionSpacing = maxHeight * 0.025;
              final bottomPadding = maxHeight * 0.05;

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    maxWidth * 0.05,
                    maxHeight * 0.03,
                    maxWidth * 0.05,
                    bottomPadding + 10.0, // Add extra fixed padding at the bottom
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Avatar - slightly reduced size
                      Hero(
                        tag: 'profileAvatar',
                        child: Container(
                          width: avatarSize * 0.95, // Slightly smaller
                          height: avatarSize * 0.95, // Slightly smaller
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child:
                                userProfile['avatarUrl'] != null
                                    ? Image.network(
                                      userProfile['avatarUrl']!,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Center(
                                            child: Text(
                                              userProfile['initialLetter'],
                                              style: TextStyle(
                                                fontSize: titleFontSize,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white.withOpacity(0.9),
                                              ),
                                            ),
                                          ),
                                    )
                                    : Center(
                                      child: Text(
                                        userProfile['initialLetter'],
                                        style: TextStyle(
                                          fontSize: titleFontSize,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white.withOpacity(0.9),
                                        ),
                                      ),
                                    ),
                          ),
                        ),
                      ),

                      SizedBox(height: verticalSpacing),

                      // Display name
                      Text(
                        userProfile['name'],
                        style: TextStyle(
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),

                      SizedBox(height: verticalSpacing * 0.4),

                      // Email
                      Text(
                        FirebaseAuth.instance.currentUser?.email ?? 'No email',
                        style: TextStyle(
                          fontSize: subtitleFontSize,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),

                      SizedBox(height: sectionSpacing),

                      // Phone Number Section
                      ListTile(
                        leading: const Icon(Icons.phone, color: Colors.white),
                        title: const Text('Phone Number', style: TextStyle(color: Colors.white)),
                        subtitle: Text(
                          // First check Firebase Auth for phone number, then fall back to userProfile
                          ref.watch(authStateProvider).value?.phoneNumber ??
                              userProfile['phoneNumber'] ??
                              'Not linked',
                          style: TextStyle(color: Colors.white.withOpacity(0.8)),
                        ),
                        trailing: TextButton(
                          onPressed: () {
                            Navigator.of(
                              context,
                            ).push(MaterialPageRoute(builder: (_) => const PhoneLinkScreen()));
                          },
                          child: const Text('Link', style: TextStyle(color: Colors.white)),
                        ),
                      ),

                      // Profile editing section
                      _buildProfileSection(
                        context,
                        buttonHeight: buttonHeight,
                        fontSize: bodyFontSize,
                        verticalSpacing: verticalSpacing,
                      ),

                      SizedBox(height: sectionSpacing),

                      // Stats section
                      _buildStatsSection(
                        context,
                        fontSize: bodyFontSize,
                        titleFontSize: subtitleFontSize,
                        rowSpacing: verticalSpacing * 0.4,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProfileSection(
    BuildContext context, {
    required double buttonHeight,
    required double fontSize,
    required double verticalSpacing,
  }) {
    final moodData = ref.watch(currentMoodDataProvider);
    final userProfile = ref.watch(userProfileProvider);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(verticalSpacing),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        children: [
          // Edit profile button
          ElevatedButton(
            onPressed: () {
              // Mock editing functionality - updates the profile name
              final updatedProfile = Map<String, dynamic>.from(userProfile);
              updatedProfile['name'] = 'Updated User';
              ref.read(userProfileProvider.notifier).state = updatedProfile;

              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: moodData.primaryColor,
              minimumSize: Size(double.infinity, buttonHeight),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Edit Profile',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
            ),
          ),

          SizedBox(height: verticalSpacing),

          // Update photo button
          OutlinedButton(
            onPressed: () {
              // Mock functionality
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Photo update coming soon!')));
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, buttonHeight),
              side: BorderSide(color: Colors.white.withOpacity(0.5)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text(
              'Update Profile Photo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(
    BuildContext context, {
    required double fontSize,
    required double titleFontSize,
    required double rowSpacing,
  }) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(fontSize),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Tene Stats',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.9),
            ),
          ),

          SizedBox(height: rowSpacing * 1.5),

          _buildStatRow('Tenes Sent', '42', fontSize),
          SizedBox(height: rowSpacing),
          _buildStatRow('Tenes Received', '38', fontSize),
          SizedBox(height: rowSpacing),
          _buildStatRow('Favorite Mood', 'Jhappi', fontSize),
          SizedBox(height: rowSpacing),
          _buildStatRow('Account Created', '2 months ago', fontSize),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, double fontSize) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: fontSize, color: Colors.white.withOpacity(0.9))),
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }
}
