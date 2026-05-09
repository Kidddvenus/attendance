import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../services/auth_service.dart';
import '../services/biometric_service.dart';
import '../services/location_service.dart';
import '../services/database_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'reports_screen.dart';
import 'student_details_screen.dart';
import 'login_screen.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  String _statusMessage = 'Ready to sign attendance.';
  Position? _currentPosition;
  String? _placeName;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
        CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));
    _fetchLocation();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchLocation() async {
    final loc = Provider.of<LocationService>(context, listen: false);
    final pos = await loc.getCurrentPosition();
    if (pos != null && mounted) {
      setState(() => _currentPosition = pos);
      final name = await loc.getPlaceName(pos.latitude, pos.longitude);
      if (mounted) setState(() => _placeName = name);
    }
  }

  void _signAttendance() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Fetching location...';
    });
    try {
      final loc = Provider.of<LocationService>(context, listen: false);
      final bio = Provider.of<BiometricService>(context, listen: false);
      final db = Provider.of<DatabaseService>(context, listen: false);
      final auth = Provider.of<AuthService>(context, listen: false);
      final user = auth.currentUser;
      if (user == null) throw Exception("User not logged in.");

      final pos = await loc.getCurrentPosition();
      if (pos == null) {
        setState(
            () => _statusMessage = 'Unable to get location. Enable GPS.');
        return;
      }

      final name = await loc.getPlaceName(pos.latitude, pos.longitude);
      setState(() {
        _currentPosition = pos;
        _placeName = name;
        _statusMessage = 'Location: $name\nAuthenticate to continue...';
      });

      final ok =
          await bio.authenticate('Verify identity to sign attendance');
      if (!ok) {
        setState(() => _statusMessage = 'Biometric authentication failed.');
        await db.logAttendance(user.uid, 'Failed Biometrics',
            latitude: pos.latitude,
            longitude: pos.longitude,
            placeName: name);
        return;
      }

      await db.logAttendance(user.uid, 'Present',
          latitude: pos.latitude,
          longitude: pos.longitude,
          placeName: name);
      setState(() => _statusMessage = 'Attendance signed successfully!');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('✅ Successfully Signed In!'),
        backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.85),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ReportsScreen()));
    } catch (e) {
      setState(() => _statusMessage = 'Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleLogout() async {
    final auth = Provider.of<AuthService>(context, listen: false);
    await auth.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    final isDark = tp.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
        actions: [
          IconButton(
              icon: const Icon(Icons.person),
              tooltip: 'Profile',
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const StudentDetailsScreen()))),
          IconButton(
              icon: const Icon(Icons.analytics),
              tooltip: 'Reports',
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ReportsScreen()))),
          IconButton(
              icon: const Icon(Icons.logout), onPressed: _handleLogout),
        ],
      ),
      body: Container(
        decoration: AppTheme.buildAuroraBackground(isDark),
        child: SafeArea(
            child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(children: [
            const SizedBox(height: 16),
            _locationCard(isDark),
            const SizedBox(height: 24),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Text(_statusMessage,
                  key: ValueKey(_statusMessage),
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const CircularProgressIndicator()
            else
              ScaleTransition(
                  scale: _pulseAnim,
                  child: SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: _signAttendance,
                      icon: const Icon(Icons.beenhere, size: 28),
                      label: const Text('Mark Attendance',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.black87,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                          elevation: 8,
                          shadowColor: AppTheme.primaryGreen
                              .withValues(alpha: 0.4)),
                    ),
                  )),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                  child: _quickLink(isDark, Icons.person_outline, 'My Profile',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StudentDetailsScreen())))),
              const SizedBox(width: 12),
              Expanded(
                  child: _quickLink(isDark, Icons.bar_chart, 'Reports',
                      () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportsScreen())))),
            ]),
          ]),
        )),
      ),
    );
  }

  Widget _locationCard(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF151C2A).withValues(alpha: 0.85)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: AppTheme.primaryBlue
                .withValues(alpha: isDark ? 0.3 : 0.15)),
        boxShadow: [
          BoxShadow(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8))
        ],
      ),
      child: Column(children: [
        Row(children: [
          Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.my_location,
                  color: AppTheme.primaryBlue, size: 24)),
          const SizedBox(width: 12),
          Expanded(
              child: Text('Your Location',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold))),
          IconButton(
              onPressed: _fetchLocation,
              icon: Icon(Icons.refresh,
                  color: isDark
                      ? AppTheme.primaryGreen
                      : AppTheme.primaryBlue),
              tooltip: 'Refresh'),
        ]),
        const SizedBox(height: 16),
        if (_currentPosition != null) ...[
          // Place name (geocoded address)
          if (_placeName != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color:
                          AppTheme.primaryGreen.withValues(alpha: 0.3))),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place,
                        size: 20, color: AppTheme.primaryGreen),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(_placeName!,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                                fontSize: 14))),
                  ]),
            )
          else
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Row(children: [
                  SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 8),
                  Text('Resolving address...',
                      style: TextStyle(fontSize: 12)),
                ])),
          const SizedBox(height: 12),
          _coordRow(isDark, 'Lat',
              _currentPosition!.latitude.toStringAsFixed(6), Icons.north),
          const SizedBox(height: 6),
          _coordRow(isDark, 'Lng',
              _currentPosition!.longitude.toStringAsFixed(6), Icons.east),
          const SizedBox(height: 8),
          Text(
              'Accuracy: ±${_currentPosition!.accuracy.toStringAsFixed(1)}m',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black45)),
        ] else
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(children: [
                const CircularProgressIndicator(strokeWidth: 2),
                const SizedBox(height: 12),
                Text('Acquiring GPS signal...',
                    style: Theme.of(context).textTheme.bodySmall),
              ])),
      ]),
    );
  }

  Widget _coordRow(
      bool isDark, String label, String value, IconData icon) {
    return Row(children: [
      Icon(icon,
          size: 16, color: isDark ? Colors.white38 : Colors.black38),
      const SizedBox(width: 8),
      Text('$label: ',
          style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black54,
              fontSize: 13)),
      Text(value,
          style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontFamily: 'monospace',
              fontSize: 14)),
    ]);
  }

  Widget _quickLink(
      bool isDark, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 14),
        decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF151C2A).withValues(alpha: 0.7)
                : Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.06))),
        child: Column(children: [
          Icon(icon,
              size: 28,
              color:
                  isDark ? AppTheme.primaryGreen : AppTheme.primaryBlue),
          const SizedBox(height: 8),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
