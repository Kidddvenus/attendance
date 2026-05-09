import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../services/location_service.dart';
import '../theme/app_theme.dart';
import '../theme/theme_provider.dart';
import 'package:intl/intl.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  Stream<QuerySnapshot>? _stream;
  String? _uid;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;
    // Only (re-)create the stream when the uid changes
    if (user != null && user.uid != _uid) {
      _uid = user.uid;
      final db = Provider.of<DatabaseService>(context, listen: false);
      _stream = db.getAttendanceReports(user.uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tp = Provider.of<ThemeProvider>(context);
    final isDark = tp.isDarkMode;
    final auth = Provider.of<AuthService>(context, listen: false);
    final user = auth.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Reports')),
      body: Container(
        decoration: AppTheme.buildAuroraBackground(isDark),
        child: user == null
            ? const Center(child: Text('Please log in to view reports.'))
            : _stream == null
                ? const Center(child: CircularProgressIndicator())
                : StreamBuilder<QuerySnapshot>(
                    stream: _stream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        return Center(
                          child: Text('Error: ${snapshot.error}',
                              style: const TextStyle(color: Colors.redAccent)),
                        );
                      }

                      // Sort client-side (newest first) — avoids Firestore composite index requirement
                      final docs = [...(snapshot.data?.docs ?? [])]
                        ..sort((a, b) {
                          final aTs = (a.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                          final bTs = (b.data() as Map<String, dynamic>)['timestamp'] as Timestamp?;
                          if (aTs == null && bTs == null) return 0;
                          if (aTs == null) return 1;
                          if (bTs == null) return -1;
                          return bTs.compareTo(aTs); // descending
                        });

                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.inbox_outlined,
                                    size: 64,
                                    color: isDark
                                        ? Colors.white24
                                        : Colors.black26),
                                const SizedBox(height: 16),
                                Text('No attendance records found.',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium),
                              ]),
                        );
                      }

                      // Compute analytics from the already-loaded docs
                      int totalPresent = 0;
                      int totalAbsent = 0;
                      for (final doc in docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if ((data['status'] as String?) == 'Present') {
                          totalPresent++;
                        } else {
                          totalAbsent++;
                        }
                      }
                      final total = docs.length;
                      final attendanceRate = total > 0
                          ? (totalPresent / total * 100).toStringAsFixed(1)
                          : '0.0';

                      return CustomScrollView(
                        slivers: [
                          // ── Analytics Summary Cards ──────────────────────
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Overview',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87)),
                                  const SizedBox(height: 14),
                                  Row(children: [
                                    Expanded(
                                        child: _StatCard(
                                      label: 'Total',
                                      value: '$total',
                                      icon: Icons.list_alt_rounded,
                                      color: isDark
                                          ? AppTheme.primaryBlue
                                          : AppTheme.primaryBlue,
                                      isDark: isDark,
                                    )),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: _StatCard(
                                      label: 'Present',
                                      value: '$totalPresent',
                                      icon: Icons.check_circle_rounded,
                                      color: AppTheme.primaryGreen,
                                      isDark: isDark,
                                    )),
                                    const SizedBox(width: 10),
                                    Expanded(
                                        child: _StatCard(
                                      label: 'Absent',
                                      value: '$totalAbsent',
                                      icon: Icons.cancel_rounded,
                                      color: Colors.redAccent,
                                      isDark: isDark,
                                    )),
                                  ]),
                                  const SizedBox(height: 10),
                                  // Attendance rate bar
                                  _AttendanceRateBar(
                                    rate: totalPresent / total,
                                    rateLabel: '$attendanceRate%',
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 20),
                                  Text('History',
                                      style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87)),
                                  const SizedBox(height: 8),
                                ],
                              ),
                            ),
                          ),

                          // ── Attendance Log List ───────────────────────────
                          SliverPadding(
                            padding:
                                const EdgeInsets.fromLTRB(16, 0, 16, 24),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final data = docs[index].data()
                                      as Map<String, dynamic>;
                                  final status =
                                      data['status'] as String? ?? 'Unknown';
                                  final lat = data['latitude'] as double?;
                                  final lng = data['longitude'] as double?;
                                  final place = data['placeName'] as String?;
                                  final Timestamp? ts =
                                      data['timestamp'] as Timestamp?;
                                  final dateStr = ts != null
                                      ? DateFormat('MMM d, yyyy – h:mm a')
                                          .format(ts.toDate())
                                      : 'Pending...';
                                  final isPresent = status == 'Present';

                                  return Card(
                                    margin:
                                        const EdgeInsets.only(bottom: 12),
                                    color: isDark
                                        ? const Color(0xFF151C2A)
                                        : Colors.white,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(14)),
                                    child: InkWell(
                                      borderRadius:
                                          BorderRadius.circular(14),
                                      onTap: () => _showDetailSheet(
                                          context,
                                          isDark,
                                          status,
                                          dateStr,
                                          lat,
                                          lng,
                                          place),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Row(children: [
                                          Container(
                                            width: 48,
                                            height: 48,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: (isPresent
                                                      ? AppTheme.primaryGreen
                                                      : Colors.redAccent)
                                                  .withValues(alpha: 0.15),
                                            ),
                                            child: Icon(
                                                isPresent
                                                    ? Icons.check_circle
                                                    : Icons.cancel,
                                                color: isPresent
                                                    ? AppTheme.primaryGreen
                                                    : Colors.redAccent,
                                                size: 28),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                              child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(status,
                                                  style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 15,
                                                      color: isPresent
                                                          ? AppTheme
                                                              .primaryGreen
                                                          : Colors
                                                              .redAccent)),
                                              const SizedBox(height: 4),
                                              Text(dateStr,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall),
                                              if (place != null &&
                                                  place.isNotEmpty) ...[
                                                const SizedBox(height: 4),
                                                Row(children: [
                                                  Icon(Icons.place,
                                                      size: 14,
                                                      color: isDark
                                                          ? AppTheme
                                                              .primaryGreen
                                                          : AppTheme
                                                              .primaryBlue),
                                                  const SizedBox(width: 4),
                                                  Expanded(
                                                      child: Text(place,
                                                          maxLines: 1,
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                          style: TextStyle(
                                                              fontSize: 12,
                                                              color: isDark
                                                                  ? Colors
                                                                      .white60
                                                                  : Colors
                                                                      .black54))),
                                                ]),
                                              ] else if (lat != null &&
                                                  lng != null) ...[
                                                const SizedBox(height: 4),
                                                _AsyncPlaceName(
                                                    lat: lat,
                                                    lng: lng,
                                                    isDark: isDark),
                                              ],
                                            ],
                                          )),
                                          Icon(Icons.chevron_right,
                                              color: isDark
                                                  ? Colors.white24
                                                  : Colors.black26),
                                        ]),
                                      ),
                                    ),
                                  );
                                },
                                childCount: docs.length,
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, bool isDark, String status,
      String dateStr, double? lat, double? lng, String? place) {
    final isPresent = status == 'Present';
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF151C2A) : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Icon(isPresent ? Icons.check_circle : Icons.cancel,
              size: 48,
              color: isPresent ? AppTheme.primaryGreen : Colors.redAccent),
          const SizedBox(height: 12),
          Text(status,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isPresent
                      ? AppTheme.primaryGreen
                      : Colors.redAccent)),
          const SizedBox(height: 8),
          Text(dateStr,
              style: TextStyle(
                  color: isDark ? Colors.white54 : Colors.black54)),
          const SizedBox(height: 20),
          if (place != null && place.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.3))),
              child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.place,
                        size: 20, color: AppTheme.primaryGreen),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(place,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppTheme.primaryGreen,
                                fontSize: 14))),
                  ]),
            ),
          if (lat != null && lng != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('GPS Coordinates',
                        style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? Colors.white38
                                : Colors.black38)),
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.north,
                          size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 6),
                      Text('Lat: ',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : Colors.black54)),
                      Text(lat.toStringAsFixed(6),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace')),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.east,
                          size: 16, color: AppTheme.primaryBlue),
                      const SizedBox(width: 6),
                      Text('Lng: ',
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white54
                                  : Colors.black54)),
                      Text(lng.toStringAsFixed(6),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace')),
                    ]),
                  ]),
            ),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

// ── Analytics Widgets ──────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151C2A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.12),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white54 : Colors.black54)),
        ],
      ),
    );
  }
}

class _AttendanceRateBar extends StatelessWidget {
  final double rate;
  final String rateLabel;
  final bool isDark;

  const _AttendanceRateBar(
      {required this.rate, required this.rateLabel, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151C2A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.primaryGreen.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Attendance Rate',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87)),
              Text(rateLabel,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGreen,
                      fontSize: 16)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: rate.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor:
                  isDark ? Colors.white12 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(
                rate >= 0.75
                    ? AppTheme.primaryGreen
                    : rate >= 0.5
                        ? Colors.orangeAccent
                        : Colors.redAccent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Async Place Name (unchanged) ─────────────────────────────────────────

class _AsyncPlaceName extends StatefulWidget {
  final double lat;
  final double lng;
  final bool isDark;

  const _AsyncPlaceName(
      {required this.lat, required this.lng, required this.isDark});

  @override
  State<_AsyncPlaceName> createState() => _AsyncPlaceNameState();
}

class _AsyncPlaceNameState extends State<_AsyncPlaceName> {
  String? _resolved;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  Future<void> _resolve() async {
    final loc = Provider.of<LocationService>(context, listen: false);
    final name = await loc.getPlaceName(widget.lat, widget.lng);
    if (mounted) setState(() => _resolved = name);
  }

  @override
  Widget build(BuildContext context) {
    if (_resolved == null) {
      return Row(children: [
        Icon(Icons.place,
            size: 14,
            color: widget.isDark ? Colors.white38 : Colors.black38),
        const SizedBox(width: 4),
        Text(
            '${widget.lat.toStringAsFixed(5)}, ${widget.lng.toStringAsFixed(5)}',
            style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: widget.isDark ? Colors.white38 : Colors.black45)),
      ]);
    }
    return Row(children: [
      Icon(Icons.place,
          size: 14,
          color: widget.isDark
              ? AppTheme.primaryGreen
              : AppTheme.primaryBlue),
      const SizedBox(width: 4),
      Expanded(
          child: Text(_resolved!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 12,
                  color:
                      widget.isDark ? Colors.white60 : Colors.black54))),
    ]);
  }
}
