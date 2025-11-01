import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.primaryColor;

    // Mock user data (replace with Supabase auth later)
    const String userName = 'Alex Johnson';
    const String userEmail = 'alex.j@example.com';
    const int totalReports = 12;
    const int karmaPoints = 1250;
    const String joinDate = 'March 2024';
    const String appVersion = '1.2.0';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Profile',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar + Name
            Column(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundColor: primary.withOpacity(0.15),
                  backgroundImage: const NetworkImage(
                    'https://i.pravatar.cc/300?img=3',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  userName,
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Stats Grid
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    label: 'Reports',
                    value: '$totalReports',
                    icon: Icons.flag,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _InfoCard(
                    label: 'Karma',
                    value: '$karmaPoints',
                    icon: Icons.star,
                    color: Colors.amber,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Info List
            _ProfileRow(label: 'Member Since', value: joinDate),
            const SizedBox(height: 12),
            _ProfileRow(label: 'App Version', value: appVersion),
            const SizedBox(height: 12),
            _ProfileRow(
              label: 'Privacy Policy',
              value: 'View',
              isLink: true,
              onTap: () {
                // TODO: Open privacy policy
              },
            ),
            const SizedBox(height: 12),
            _ProfileRow(
              label: 'Terms of Service',
              value: 'View',
              isLink: true,
              onTap: () {
                // TODO: Open terms
              },
            ),

            const SizedBox(height: 40),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  // TODO: Supabase sign out
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Logged out successfully',
                        style: GoogleFonts.poppins(),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/welcome',
                        (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Logout',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// REUSABLE INFO CARD
// ============================================================================
class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// REUSABLE PROFILE ROW
// ============================================================================
class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;

  const _ProfileRow({
    required this.label,
    required this.value,
    this.isLink = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLink ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            Row(
              children: [
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: isLink ? FontWeight.w600 : FontWeight.normal,
                    color: isLink ? Theme.of(context).primaryColor : null,
                  ),
                ),
                if (isLink) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 14,
                    color: Theme.of(context).primaryColor,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}