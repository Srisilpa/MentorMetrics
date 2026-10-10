import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';
import '../../widgets/star_rating_bar.dart';

class FeedbackRecordsScreen extends StatefulWidget {
  const FeedbackRecordsScreen({super.key});

  @override
  State<FeedbackRecordsScreen> createState() => _FeedbackRecordsScreenState();
}

class _FeedbackRecordsScreenState extends State<FeedbackRecordsScreen> {
  List<dynamic> _records = [];
  List<dynamic> _facultyList = [];
  List<dynamic> _departments = [];

  bool _loading = true;
  String? _errorMessage;

  int? _filterFacultyId;
  int? _filterDeptId;
  int? _filterRating;
  String _searchQuery = '';
  int _currentPage = 1;
  int _totalPages = 1;
  int _totalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final fac = await ApiService.getFaculty(activeOnly: false);
      final depts = await ApiService.getDepartments();
      if (mounted) {
        setState(() {
          _facultyList = fac;
          _departments = depts;
        });
      }
    } catch (_) {}
    _fetchRecords();
  }

  Future<void> _fetchRecords({int page = 1}) async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final res = await ApiService.getAdminFeedbackRecords(
        facultyId: _filterFacultyId,
        departmentId: _filterDeptId,
        rating: _filterRating,
        search: _searchQuery.isNotEmpty ? _searchQuery : null,
        page: page,
        pageSize: 15,
      );

      if (mounted) {
        setState(() {
          _records = res['items'] ?? [];
          _currentPage = res['page'] ?? 1;
          _totalPages = res['total_pages'] ?? 1;
          _totalCount = res['total'] ?? 0;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _loading = false;
        });
      }
    }
  }

  void _showRecordDetailDialog(Map<String, dynamic> r) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.feedback_rounded, color: Color(0xFF2563EB)),
            const SizedBox(width: 10),
            Text('Feedback Record #${r['id']}'),
          ],
        ),
        content: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Faculty:', r['faculty_name'] ?? 'Unknown'),
                _buildDetailRow('Department:', r['department'] ?? 'General'),
                _buildDetailRow('Subject:', r['subject'] ?? 'Subject'),
                _buildDetailRow('Evaluator:', r['student_name'] ?? 'Student'),
                _buildDetailRow(
                  'Date:',
                  r['created_at'] != null
                      ? DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(r['created_at']))
                      : 'N/A',
                ),
                const Divider(height: 24),
                const Text(
                  'Individual Criteria Ratings:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 10),
                _buildRatingBarRow('Teaching Quality', r['teaching_quality']),
                _buildRatingBarRow('Subject Knowledge', r['subject_knowledge']),
                _buildRatingBarRow('Communication', r['communication']),
                _buildRatingBarRow('Punctuality', r['punctuality']),
                _buildRatingBarRow('Overall Satisfaction', r['overall_satisfaction']),
                const Divider(height: 24),
                const Text(
                  'Written Student Comments:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    r['comments'] != null && r['comments'].toString().trim().isNotEmpty
                        ? '“${r['comments']}”'
                        : 'No written comments provided.',
                    style: TextStyle(
                      fontStyle: r['comments'] != null && r['comments'].toString().trim().isNotEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                      color: const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.blueGrey)),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.bold))),
        ],
      ),
    );
  }

  Widget _buildRatingBarRow(String label, dynamic score) {
    final int val = score is int ? score : 5;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
          Row(
            children: List.generate(
              5,
              (i) => Icon(
                i < val ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 16,
                color: i < val ? const Color(0xFFF59E0B) : Colors.grey.shade300,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$val/5', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _handleExportCsv() async {
    try {
      final csv = await ApiService.downloadFeedbackCsv(
        facultyId: _filterFacultyId,
        departmentId: _filterDeptId,
        rating: _filterRating,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.download_done_rounded, color: Colors.green),
              SizedBox(width: 10),
              Text('Feedback Export CSV'),
            ],
          ),
          content: SizedBox(
            width: 600,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'CSV generated successfully from filtered records:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      csv,
                      style: const TextStyle(
                        color: Colors.white,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            ElevatedButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export error: ${e.toString().replaceFirst('Exception: ', '')}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Feedback Submissions & Records',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 4),
                Text('Total $_totalCount submissions recorded across departments.',
                    style: const TextStyle(color: Colors.blueGrey, fontSize: 13)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _handleExportCsv,
              icon: const Icon(Icons.file_download_outlined),
              label: const Text('Export to CSV'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F172A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Filter toolbar
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Wrap(
              spacing: 14,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: 250,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search keyword...',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (val) {
                      _searchQuery = val;
                      _fetchRecords(page: 1);
                    },
                  ),
                ),
                DropdownButton<int?>(
                  value: _filterDeptId,
                  hint: const Text('All Departments'),
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('All Departments')),
                    ..._departments.map((d) => DropdownMenuItem<int?>(value: d['id'] as int, child: Text(d['name']))),
                  ],
                  onChanged: (val) {
                    setState(() => _filterDeptId = val);
                    _fetchRecords(page: 1);
                  },
                ),
                DropdownButton<int?>(
                  value: _filterFacultyId,
                  hint: const Text('All Faculty'),
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('All Faculty')),
                    ..._facultyList.map((f) => DropdownMenuItem<int?>(value: f['id'] as int, child: Text(f['name']))),
                  ],
                  onChanged: (val) {
                    setState(() => _filterFacultyId = val);
                    _fetchRecords(page: 1);
                  },
                ),
                DropdownButton<int?>(
                  value: _filterRating,
                  hint: const Text('All Ratings'),
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem<int?>(value: null, child: Text('All Ratings')),
                    DropdownMenuItem<int?>(value: 5, child: Text('5 Stars ★★★★★')),
                    DropdownMenuItem<int?>(value: 4, child: Text('4 Stars ★★★★')),
                    DropdownMenuItem<int?>(value: 3, child: Text('3 Stars ★★★')),
                    DropdownMenuItem<int?>(value: 2, child: Text('2 Stars ★★')),
                    DropdownMenuItem<int?>(value: 1, child: Text('1 Star ★')),
                  ],
                  onChanged: (val) {
                    setState(() => _filterRating = val);
                    _fetchRecords(page: 1);
                  },
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    setState(() {
                      _filterFacultyId = null;
                      _filterDeptId = null;
                      _filterRating = null;
                      _searchQuery = '';
                    });
                    _fetchRecords(page: 1);
                  },
                  icon: const Icon(Icons.clear_all_rounded, size: 18),
                  label: const Text('Clear Filters'),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),

        if (_loading)
          const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
        else if (_errorMessage != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            ),
          )
        else if (_records.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const Icon(Icons.inbox_rounded, size: 56, color: Colors.blueGrey),
                  const SizedBox(height: 12),
                  const Text('No feedback records match the current filters.',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () => _fetchRecords(page: 1), child: const Text('Refresh')),
                ],
              ),
            ),
          )
        else ...[
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _records.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final r = _records[index];
              final dateStr = r['created_at'] != null
                  ? DateFormat('yyyy-MM-dd').format(DateTime.parse(r['created_at']))
                  : '';

              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: StarRatingBar.getRatingColor(r['rating'] ?? 5).withAlpha(30),
                    child: Text(
                      '${r['rating']}★',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: StarRatingBar.getRatingColor(r['rating'] ?? 5),
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(r['faculty_name'] ?? 'Faculty', style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          r['department'] ?? 'General',
                          style: const TextStyle(fontSize: 11, color: Colors.blueGrey),
                        ),
                      ),
                    ],
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('Subject: ${r['subject']}  •  Date: $dateStr',
                          style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                      if (r['comments'] != null && r['comments'].toString().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          '“${r['comments']}”',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                  onTap: () => _showRecordDetailDialog(r),
                ),
              );
            },
          ),
          const SizedBox(height: 16),

          // Pagination
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: _currentPage > 1 ? () => _fetchRecords(page: _currentPage - 1) : null,
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Text('Page $_currentPage of $_totalPages',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              IconButton(
                onPressed: _currentPage < _totalPages ? () => _fetchRecords(page: _currentPage + 1) : null,
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
