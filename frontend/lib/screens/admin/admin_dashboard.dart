import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../services/session_service.dart';
import '../../services/api_service.dart';
import '../../widgets/star_rating_bar.dart';
import '../welcome_screen.dart';
import 'faculty_management.dart';
import 'subject_management.dart';
import 'feedback_records_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedNavIndex = 0; // 0: Analytics, 1: Faculty, 2: Subjects, 3: Records
  String _adminName = 'Administrator';
  bool _loadingAnalytics = true;
  String? _analyticsError;
  Map<String, dynamic> _analyticsData = {};

  @override
  void initState() {
    super.initState();
    _loadAdminInfo();
    _fetchAnalytics();
  }

  Future<void> _loadAdminInfo() async {
    final name = await SessionService.getUserName();
    if (mounted) setState(() => _adminName = name);
  }

  Future<void> _fetchAnalytics() async {
    setState(() {
      _loadingAnalytics = true;
      _analyticsError = null;
    });

    try {
      final data = await ApiService.getAdminAnalytics();
      if (mounted) {
        setState(() {
          _analyticsData = data;
          _loadingAnalytics = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _analyticsError = e.toString().replaceFirst('Exception: ', '');
          _loadingAnalytics = false;
        });
      }
    }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to end your administrator session?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await SessionService.clearSession();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'MentorMetrics',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Institutional Admin Dashboard',
                  style: TextStyle(fontSize: 11, color: Colors.blueGrey),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Signed in as $_adminName',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF475569)),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: Color(0xFF64748B)),
            onPressed: _logout,
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedNavIndex,
              onTap: (index) => setState(() => _selectedNavIndex = index),
              selectedItemColor: const Color(0xFF2563EB),
              unselectedItemColor: Colors.blueGrey,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Analytics'),
                BottomNavigationBarItem(icon: Icon(Icons.people_rounded), label: 'Faculty'),
                BottomNavigationBarItem(icon: Icon(Icons.menu_book_rounded), label: 'Subjects'),
                BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Records'),
              ],
            ),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isDesktop)
            Container(
              width: 250,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  _buildSidebarItem(0, Icons.dashboard_rounded, 'Analytics Overview'),
                  _buildSidebarItem(1, Icons.people_rounded, 'Faculty Management'),
                  _buildSidebarItem(2, Icons.menu_book_rounded, 'Subject Catalog'),
                  _buildSidebarItem(3, Icons.receipt_long_rounded, 'Feedback Records'),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton.icon(
                      onPressed: _fetchAnalytics,
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: const Text('Refresh Data'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 44),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200),
                  child: _buildCurrentView(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(int index, IconData icon, String label) {
    final isSelected = _selectedNavIndex == index;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tileColor: isSelected ? const Color(0xFFEFF6FF) : Colors.transparent,
        leading: Icon(
          icon,
          color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF64748B),
        ),
        title: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF334155),
          ),
        ),
        onTap: () => setState(() => _selectedNavIndex = index),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedNavIndex) {
      case 1:
        return const FacultyManagementScreen();
      case 2:
        return const SubjectManagementScreen();
      case 3:
        return const FeedbackRecordsScreen();
      case 0:
      default:
        return _buildAnalyticsView();
    }
  }

  Widget _buildAnalyticsView() {
    if (_loadingAnalytics) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(60),
          child: Column(
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Calculating institutional feedback metrics...'),
            ],
          ),
        ),
      );
    }

    if (_analyticsError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_analyticsError!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _fetchAnalytics, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final totalFaculty = _analyticsData['total_faculty'] ?? 0;
    final totalStudents = _analyticsData['total_students'] ?? 0;
    final totalFeedback = _analyticsData['total_feedback'] ?? 0;
    final avgRating = (_analyticsData['average_rating'] as num?)?.toDouble() ?? 0.0;

    final dist = (_analyticsData['rating_distribution'] as Map<String, dynamic>?) ?? {};
    final facultyRatings = (_analyticsData['faculty_ratings'] as List<dynamic>?) ?? [];
    final subjectCounts = (_analyticsData['subject_counts'] as List<dynamic>?) ?? [];
    final deptComparison = (_analyticsData['department_comparison'] as List<dynamic>?) ?? [];
    final timelineTrends = (_analyticsData['timeline_trends'] as List<dynamic>?) ?? [];
    final recentFeedback = (_analyticsData['recent_feedback'] as List<dynamic>?) ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Academic Analytics & Feedback Overview',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 4),
                Text('Real-time data aggregated directly from MySQL feedback records.',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
              ],
            ),
            IconButton(
              tooltip: 'Refresh Analytics',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _fetchAnalytics,
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Summary Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final int crossAxisCount = constraints.maxWidth >= 950 ? 4 : (constraints.maxWidth >= 550 ? 2 : 1);
            return GridView.count(
              crossAxisCount: crossAxisCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 2.2,
              children: [
                _buildSummaryCard(
                  title: 'Active Faculty',
                  value: totalFaculty.toString(),
                  icon: Icons.people_alt_rounded,
                  color: const Color(0xFF2563EB),
                ),
                _buildSummaryCard(
                  title: 'Enrolled Students',
                  value: totalStudents.toString(),
                  icon: Icons.school_rounded,
                  color: const Color(0xFF059669),
                ),
                _buildSummaryCard(
                  title: 'Feedback Submissions',
                  value: totalFeedback.toString(),
                  icon: Icons.assignment_turned_in_rounded,
                  color: const Color(0xFF7C3AED),
                ),
                _buildSummaryCard(
                  title: 'Average Rating',
                  value: '${avgRating.toStringAsFixed(1)} ★',
                  icon: Icons.star_rounded,
                  color: const Color(0xFFD97706),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),

        const Text(
          'Visual Analytics & Trends',
          style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
        const SizedBox(height: 16),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildRatingDistributionCard(dist)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildFacultyRatingsCard(facultyRatings)),
                    ],
                  )
                : Column(
                    children: [
                      _buildRatingDistributionCard(dist),
                      const SizedBox(height: 20),
                      _buildFacultyRatingsCard(facultyRatings),
                    ],
                  );
          },
        ),
        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _buildSubjectCountsCard(subjectCounts)),
                      const SizedBox(width: 20),
                      Expanded(child: _buildDepartmentComparisonCard(deptComparison)),
                    ],
                  )
                : Column(
                    children: [
                      _buildSubjectCountsCard(subjectCounts),
                      const SizedBox(height: 20),
                      _buildDepartmentComparisonCard(deptComparison),
                    ],
                  );
          },
        ),
        const SizedBox(height: 20),

        _buildTimelineTrendsCard(timelineTrends),
        const SizedBox(height: 32),

        _buildRecentSubmissionsTable(recentFeedback),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 12, color: Colors.blueGrey, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Chart 1: Rating Distribution (1 to 5 Stars)
  Widget _buildRatingDistributionCard(Map<String, dynamic> dist) {
    double maxCount = 1;
    for (int star = 1; star <= 5; star++) {
      final c = (dist[star.toString()] as num?)?.toDouble() ?? 0;
      if (c > maxCount) maxCount = c;
    }

    final barGroups = List.generate(5, (i) {
      final star = i + 1;
      final count = (dist[star.toString()] as num?)?.toDouble() ?? 0.0;
      return BarChartGroupData(
        x: star,
        barRods: [
          BarChartRodData(
            toY: count,
            color: StarRatingBar.getRatingColor(star),
            width: 24,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
          ),
        ],
      );
    });

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text(
                  '1. Star Rating Distribution',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Frequency of 1 to 5 star scores given by students.',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
            const SizedBox(height: 24),
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxCount + 2,
                  gridData: const FlGridData(drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (val, meta) => Text(
                          val.toInt().toString(),
                          style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.toInt()} ★',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ),
                    ),
                  ),
                  barGroups: barGroups,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Chart 2: Average Rating by Faculty Member
  Widget _buildFacultyRatingsCard(List<dynamic> facultyRatings) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.leaderboard_rounded, color: Color(0xFF059669)),
                SizedBox(width: 8),
                Text(
                  '2. Faculty Performance Ranking',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Average score out of 5 based on student feedback.',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
            const SizedBox(height: 16),
            if (facultyRatings.isEmpty)
              const SizedBox(height: 200, child: Center(child: Text('No faculty feedback recorded.')))
            else
              SizedBox(
                height: 220,
                child: ListView.separated(
                  itemCount: facultyRatings.take(6).length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) {
                    final item = facultyRatings[i];
                    final double avg = (item['average_rating'] as num?)?.toDouble() ?? 0.0;
                    final int count = item['feedback_count'] ?? 0;

                    return Row(
                      children: [
                        SizedBox(
                          width: 140,
                          child: Text(
                            item['faculty_name'] ?? '',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: avg / 5.0,
                              minHeight: 10,
                              backgroundColor: const Color(0xFFF1F5F9),
                              valueColor: AlwaysStoppedAnimation<Color>(StarRatingBar.getRatingColor(avg.round())),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${avg.toStringAsFixed(1)} ★ ($count)',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Chart 3: Feedback Count by Subject
  Widget _buildSubjectCountsCard(List<dynamic> subjectCounts) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.collections_bookmark_rounded, color: Color(0xFF7C3AED)),
                SizedBox(width: 8),
                Text(
                  '3. Feedback Count by Course',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Evaluation participation volume per subject.',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
            const SizedBox(height: 16),
            if (subjectCounts.isEmpty)
              const SizedBox(height: 200, child: Center(child: Text('No subject feedback data.')))
            else
              SizedBox(
                height: 220,
                child: ListView.separated(
                  itemCount: subjectCounts.take(6).length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final item = subjectCounts[i];
                    final count = item['feedback_count'] ?? 0;
                    final code = item['subject_code'] ?? '';
                    final name = item['subject_name'] ?? '';

                    return Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(code, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('$count submissions',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF7C3AED))),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Chart 4: Department-wise Feedback Comparison
  Widget _buildDepartmentComparisonCard(List<dynamic> deptComparison) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.domain_rounded, color: Color(0xFFD97706)),
                SizedBox(width: 8),
                Text(
                  '4. Department-Wise Comparison',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Average faculty ratings across academic branches.',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
            const SizedBox(height: 16),
            if (deptComparison.isEmpty)
              const SizedBox(height: 200, child: Center(child: Text('No department data.')))
            else
              SizedBox(
                height: 220,
                child: ListView.separated(
                  itemCount: deptComparison.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final item = deptComparison[i];
                    final double avg = (item['average_rating'] as num?)?.toDouble() ?? 0.0;
                    final int count = item['feedback_count'] ?? 0;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(item['department'] ?? 'Dept',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
                            Text('${avg.toStringAsFixed(1)} ★  ($count submissions)',
                                style: const TextStyle(fontSize: 11, color: Colors.blueGrey)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: avg / 5.0,
                            minHeight: 8,
                            backgroundColor: const Color(0xFFF1F5F9),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD97706)),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Chart 5: Feedback Trends Over Time
  Widget _buildTimelineTrendsCard(List<dynamic> timelineTrends) {
    final spots = <FlSpot>[];
    for (int i = 0; i < timelineTrends.length; i++) {
      final double c = (timelineTrends[i]['count'] as num?)?.toDouble() ?? 0.0;
      spots.add(FlSpot(i.toDouble(), c));
    }

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.timeline_rounded, color: Color(0xFF2563EB)),
                SizedBox(width: 8),
                Text(
                  '5. Feedback Submission Trends Over Time',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text('Daily submission activity timeline and volume tracking.',
                style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
            const SizedBox(height: 24),
            if (spots.isEmpty)
              const SizedBox(height: 180, child: Center(child: Text('No timeline submissions yet.')))
            else
              SizedBox(
                height: 180,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(drawVerticalLine: false),
                    borderData: FlBorderData(show: false),
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 28,
                          getTitlesWidget: (v, m) => Text(v.toInt().toString(), style: const TextStyle(fontSize: 10)),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, m) {
                            final idx = v.toInt();
                            if (idx >= 0 && idx < timelineTrends.length) {
                              final dStr = timelineTrends[idx]['date'] ?? '';
                              return Text(dStr.length > 5 ? dStr.substring(5) : dStr,
                                  style: const TextStyle(fontSize: 10, color: Colors.blueGrey));
                            }
                            return const Text('');
                          },
                        ),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: spots,
                        isCurved: true,
                        color: const Color(0xFF2563EB),
                        barWidth: 3,
                        dotData: const FlDotData(show: true),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // 6. Recent Feedback Submissions Table
  Widget _buildRecentSubmissionsTable(List<dynamic> recentFeedback) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.history_rounded, color: Color(0xFF0F172A)),
                    SizedBox(width: 8),
                    Text(
                      'Recent Student Evaluations',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => setState(() => _selectedNavIndex = 3),
                  child: const Text('View All Records →'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (recentFeedback.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: Text('No recent submissions.')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentFeedback.take(5).length,
                separatorBuilder: (_, _) => const Divider(height: 18),
                itemBuilder: (context, i) {
                  final r = recentFeedback[i];
                  return Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: StarRatingBar.getRatingColor(r['rating'] ?? 5).withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${r['rating']}★',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: StarRatingBar.getRatingColor(r['rating'] ?? 5),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r['faculty_name'] ?? 'Faculty', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('${r['subject']} • ${r['department']}',
                                style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                          ],
                        ),
                      ),
                      if (r['comments'] != null && r['comments'].toString().isNotEmpty)
                        Flexible(
                          child: Text(
                            '“${r['comments']}”',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF475569)),
                          ),
                        ),
                    ],
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}