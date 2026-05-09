import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'package:intl/intl.dart';
import 'reports_screen.dart';

class StudentDetailsScreen extends StatefulWidget {
  const StudentDetailsScreen({super.key});

  @override
  State<StudentDetailsScreen> createState() => _StudentDetailsScreenState();
}

class _StudentDetailsScreenState extends State<StudentDetailsScreen> {
  Map<String, int> _summary = {'total': 0, 'present': 0, 'failed': 0};

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  Future<void> _loadSummary() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final user = auth.currentUser;
    if (user == null) return;
    final s = await db.getAttendanceSummary(user.uid);
    if (mounted) setState(() => _summary = s);
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    final isDark = tp.isDarkMode;
    final auth = Provider.of<AuthService>(context, listen: false);
    final db = Provider.of<DatabaseService>(context, listen: false);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Student Details')),
      body: Container(
        decoration: AppTheme.buildAuroraBackground(isDark),
        child: user == null
            ? const Center(child: Text('Please log in.'))
            : FutureBuilder<Map<String, dynamic>?>(
                future: db.getUserProfile(user.uid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final profile = snap.data;
                  final firstName = profile?['firstName'] ?? 'N/A';
                  final lastName = profile?['lastName'] ?? '';
                  final email =
                      profile?['email'] ?? user.email ?? 'N/A';
                  final regNumber =
                      profile?['registrationNumber'] ?? 'N/A';
                  final Timestamp? createdAt = profile?['createdAt'];
                  final joined = createdAt != null
                      ? DateFormat('MMM d, yyyy')
                          .format(createdAt.toDate())
                      : 'Unknown';
                  final initials =
                      '${firstName.isNotEmpty ? firstName[0] : ''}${lastName.isNotEmpty ? lastName[0] : ''}'
                          .toUpperCase();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                              colors: [
                                AppTheme.primaryBlue,
                                AppTheme.primaryPurple
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                          boxShadow: [
                            BoxShadow(
                                color: AppTheme.primaryBlue
                                    .withValues(alpha: 0.35),
                                blurRadius: 20,
                                offset: const Offset(0, 8))
                          ],
                        ),
                        child: Center(
                            child: Text(initials,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold))),
                      ),
                      const SizedBox(height: 16),
                      Text('$firstName $lastName',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(email,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.black54)),
                      const SizedBox(height: 24),

                      // Info Card
                      _infoCard(isDark, [
                        _infoRow(
                            Icons.badge, 'Reg Number', regNumber, isDark),
                        const Divider(height: 24),
                        _infoRow(
                            Icons.email_outlined, 'Email', email, isDark),
                        const Divider(height: 24),
                        _infoRow(Icons.calendar_today, 'Joined', joined,
                            isDark),
                      ]),

                      const SizedBox(height: 20),

                      // Summary Stats
                      Text('Attendance Summary',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _statTile(isDark, 'Total',
                                _summary['total']!, AppTheme.primaryBlue)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _statTile(
                                isDark,
                                'Present',
                                _summary['present']!,
                                AppTheme.primaryGreen)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _statTile(isDark, 'Failed',
                                _summary['failed']!, Colors.redAccent)),
                      ]),

                      const SizedBox(height: 24),

                      // Recent Records header + View All
                      Row(children: [
                        Expanded(
                            child: Text('Recent Attendance',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontWeight: FontWeight.bold))),
                        TextButton(
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ReportsScreen())),
                          child: const Text('View All →'),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      _recentList(isDark, db, user.uid),
                    ]),
                  );
                },
              ),
      ),
    );
  }

  Widget _infoCard(bool isDark, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF151C2A).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(
      IconData icon, String label, String value, bool isDark) {
    return Row(children: [
      Icon(icon,
          size: 20,
          color: isDark ? AppTheme.primaryBlue : AppTheme.primaryPurple),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark ? Colors.white38 : Colors.black38)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ]),
      ),
    ]);
  }

  Widget _statTile(
      bool isDark, String label, int count, Color accent) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF151C2A).withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Text('$count',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: accent)),
        const SizedBox(height: 4),
        Text(label,
            style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white54 : Colors.black54)),
      ]),
    );
  }

  Widget _recentList(
      bool isDark, DatabaseService db, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: db.getAttendanceReports(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(strokeWidth: 2));
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No records yet.'));
        }
        final docs = snap.data!.docs.take(5).toList();
        return Column(
            children: docs.map((doc) {
          final d = doc.data() as Map<String, dynamic>;
          final status = d['status'] as String? ?? 'Unknown';
          final lat = d['latitude'] as double?;
          final lng = d['longitude'] as double?;
          final place = d['placeName'] as String?;
          final Timestamp? ts = d['timestamp'] as Timestamp?;
          final dateStr = ts != null
              ? DateFormat('MMM d, yyyy – h:mm a')
                  .format(ts.toDate())
              : 'Pending...';
          final isPresent = status == 'Present';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            color: isDark ? const Color(0xFF151C2A) : Colors.white,
            elevation: 2,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            child: ListTile(
              leading: CircleAvatar(
                  backgroundColor: isPresent
                      ? AppTheme.primaryGreen
                      : Colors.redAccent,
                  child: Icon(isPresent ? Icons.check : Icons.close,
                      color: Colors.white)),
              title: Text(status,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPresent
                          ? AppTheme.primaryGreen
                          : Colors.redAccent)),
              subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dateStr),
                    if (place != null && place.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.place,
                            size: 13, color: AppTheme.primaryGreen),
                        const SizedBox(width: 4),
                        Expanded(
                            child: Text(place,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.primaryGreen))),
                      ])
                    else if (lat != null && lng != null)
                      _ResolvedPlace(
                          lat: lat, lng: lng, isDark: isDark),
                  ]),
            ),
          );
        }).toList());
      },
    );
  }
}

/// Resolves lat/lng to a place name for older records.
class _ResolvedPlace extends StatefulWidget {
  final double lat;
  final double lng;
  final bool isDark;

  const _ResolvedPlace(
      {required this.lat, required this.lng, required this.isDark});

  @override
  State<_ResolvedPlace> createState() => _ResolvedPlaceState();
}

class _ResolvedPlaceState extends State<_ResolvedPlace> {
  String? _name;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final loc = Provider.of<LocationService>(context, listen: false);
    final n = await loc.getPlaceName(widget.lat, widget.lng);
    if (mounted) setState(() => _name = n);
  }

  @override
  Widget build(BuildContext context) {
    if (_name == null) {
      return Text(
          '${widget.lat.toStringAsFixed(5)}, ${widget.lng.toStringAsFixed(5)}',
          style: const TextStyle(fontFamily: 'monospace', fontSize: 11));
    }
    return Row(children: [
      const Icon(Icons.place, size: 13, color: AppTheme.primaryGreen),
      const SizedBox(width: 4),
      Expanded(
          child: Text(_name!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 11, color: AppTheme.primaryGreen))),
    ]);
  }
}
