import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tene/providers/providers.dart';
import 'package:tene/providers/auth_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final moodData = ref.watch(currentMoodDataProvider);
    final user = ref.watch(authStateProvider).value;

    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please sign in to view your profile')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: moodData.primaryColor,
        foregroundColor: Colors.black,
      ),
      body: ListView(
        children: [
          // Profile Section
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: moodData.primaryColor.withOpacity(0.1),
              border: Border(bottom: BorderSide(color: moodData.primaryColor.withOpacity(0.2))),
            ),
            child: Column(
              children: [
                // Profile Avatar with Hero Animation
                Hero(
                  tag: 'profileAvatar',
                  flightShuttleBuilder: (
                    BuildContext flightContext,
                    Animation<double> animation,
                    HeroFlightDirection flightDirection,
                    BuildContext fromHeroContext,
                    BuildContext toHeroContext,
                  ) {
                    return Material(
                      color: Colors.transparent,
                      child: AnimatedBuilder(
                        animation: animation,
                        builder: (context, child) {
                          return Transform.scale(scale: animation.value, child: child);
                        },
                        child: CircleAvatar(
                          radius: 50,
                          backgroundColor: moodData.primaryColor.withOpacity(0.2),
                          child:
                              user.photoURL != null
                                  ? ClipOval(
                                    child: Image.network(
                                      user.photoURL!,
                                      width: 100,
                                      height: 100,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => Text(
                                            user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                                            style: TextStyle(
                                              color: moodData.primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 40,
                                            ),
                                          ),
                                    ),
                                  )
                                  : Text(
                                    user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                                    style: TextStyle(
                                      color: moodData.primaryColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 40,
                                    ),
                                  ),
                        ),
                      ),
                    );
                  },
                  child: Material(
                    color: Colors.transparent,
                    child: CircleAvatar(
                      radius: 50,
                      backgroundColor: moodData.primaryColor.withOpacity(0.2),
                      child:
                          user.photoURL != null
                              ? ClipOval(
                                child: Image.network(
                                  user.photoURL!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder:
                                      (_, __, ___) => Text(
                                        user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                                        style: TextStyle(
                                          color: moodData.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 40,
                                        ),
                                      ),
                                ),
                              )
                              : Text(
                                user.displayName?.substring(0, 1).toUpperCase() ?? 'U',
                                style: TextStyle(
                                  color: moodData.primaryColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 40,
                                ),
                              ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // User Info Cards
                _buildInfoCard(
                  title: 'Display Name',
                  value: user.displayName ?? 'Not set',
                  icon: Icons.person,
                  color: moodData.primaryColor,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Email',
                  value: user.email ?? 'Not set',
                  icon: Icons.email,
                  color: moodData.primaryColor,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  title: 'Phone Number',
                  value: user.phoneNumber ?? 'Not set',
                  icon: Icons.phone,
                  color: moodData.primaryColor,
                ),
              ],
            ),
          ),

          // Logout Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
              },
              icon: const Icon(Icons.logout),
              label: const Text('Sign Out'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade400,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
