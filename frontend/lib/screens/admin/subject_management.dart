import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class SubjectManagementScreen extends StatefulWidget {
  const SubjectManagementScreen({super.key});

  @override
  State<SubjectManagementScreen> createState() => _SubjectManagementScreenState();
}

class _SubjectManagementScreenState extends State<SubjectManagementScreen> {
  List<dynamic> _subjects = [];
  List<dynamic> _departments = [];
  bool _loading = true;
  String? _errorMessage;
  String _searchQuery = '';
  int? _filterDeptId;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final subs = await ApiService.getSubjects(activeOnly: false);
      final depts = await ApiService.getDepartments();

      if (mounted) {
        setState(() {
          _subjects = subs;
          _departments = depts;
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

  Future<void> _toggleStatus(int id, bool currentStatus) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ApiService.updateSubjectStatus(id, !currentStatus);
      await _loadData();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              !currentStatus ? 'Subject activated.' : 'Subject deactivated.',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    }
  }

  void _showAddEditSubjectDialog([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final codeCtrl = TextEditingController(text: item?['subject_code'] ?? '');
    final nameCtrl = TextEditingController(text: item?['subject_name'] ?? '');
    final semCtrl = TextEditingController(text: item?['semester'] ?? 'Semester 5');
    int? selectedDeptId = item?['department_id'];

    if (selectedDeptId == null && _departments.isNotEmpty) {
      selectedDeptId = _departments.first['id'];
    }

    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text(isEdit ? 'Edit Subject Details' : 'Add New Subject'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: codeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subject Code * (e.g. CS301)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.tag_rounded),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Subject Title *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    DropdownButtonFormField<int>(
                      initialValue: selectedDeptId,
                      decoration: const InputDecoration(
                        labelText: 'Department *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.apartment_rounded),
                      ),
                      items: _departments.map((d) {
                        return DropdownMenuItem<int>(
                          value: d['id'] as int,
                          child: Text(d['name'] as String),
                        );
                      }).toList(),
                      onChanged: (val) => setModalState(() => selectedDeptId = val),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: semCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Semester (e.g. Semester 5)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final code = codeCtrl.text.trim();
                  final name = nameCtrl.text.trim();
                  final sem = semCtrl.text.trim();

                  if (code.isEmpty || name.isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Subject code and title are required.')),
                    );
                    return;
                  }

                  try {
                    if (isEdit) {
                      await ApiService.updateSubject(item['id'], {
                        'subject_code': code,
                        'subject_name': name,
                        'department_id': selectedDeptId,
                        'semester': sem,
                      });
                    } else {
                      await ApiService.createSubject({
                        'subject_code': code,
                        'subject_name': name,
                        'department_id': selectedDeptId,
                        'semester': sem,
                      });
                    }

                    if (mounted) {
                      nav.pop();
                      _loadData();
                      messenger.showSnackBar(
                        SnackBar(content: Text(isEdit ? 'Subject updated.' : 'Subject added successfully.')),
                      );
                    }
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
                    );
                  }
                },
                child: Text(isEdit ? 'Save Changes' : 'Add Subject'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _subjects.where((s) {
      final code = (s['subject_code'] ?? '').toString().toLowerCase();
      final name = (s['subject_name'] ?? '').toString().toLowerCase();
      final matchQuery = code.contains(_searchQuery.toLowerCase()) || name.contains(_searchQuery.toLowerCase());
      final matchDept = _filterDeptId == null || s['department_id'] == _filterDeptId;
      return matchQuery && matchDept;
    }).toList();

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
                  'Academic Subject Catalog',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 4),
                Text('Manage curriculum subjects, semester courses, and department offerings.',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddEditSubjectDialog(),
              icon: const Icon(Icons.library_add_rounded),
              label: const Text('Add Subject'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search by subject code (e.g. CS301) or title...',
                      prefixIcon: Icon(Icons.search_rounded),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val),
                  ),
                ),
                const SizedBox(width: 14),
                DropdownButton<int?>(
                  value: _filterDeptId,
                  hint: const Text('All Departments'),
                  underline: const SizedBox(),
                  items: [
                    const DropdownMenuItem<int?>(value: null, child: Text('All Departments')),
                    ..._departments.map((d) => DropdownMenuItem<int?>(value: d['id'] as int, child: Text(d['name']))),
                  ],
                  onChanged: (val) => setState(() => _filterDeptId = val),
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
        else if (filtered.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  const Icon(Icons.menu_book_rounded, size: 56, color: Colors.blueGrey),
                  const SizedBox(height: 12),
                  const Text('No subjects found.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Try adjusting your search filter or add a new subject.',
                      style: TextStyle(color: Colors.blueGrey)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _loadData, child: const Text('Refresh')),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final sub = filtered[index];
              final bool isActive = sub['is_active'] == true;

              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: isActive ? const Color(0xFFE2E8F0) : Colors.red.shade100),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isActive ? const Color(0xFFEFF6FF) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sub['subject_code'] ?? 'SUB',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isActive ? const Color(0xFF2563EB) : Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  sub['subject_name'] ?? '',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isActive ? Colors.green.shade50 : Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    isActive ? 'Active' : 'Inactive',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: isActive ? Colors.green.shade700 : Colors.red.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${sub['department_name'] ?? 'General'} • ${sub['semester'] ?? 'All Semesters'}',
                              style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade700),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Edit subject',
                        icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                        onPressed: () => _showAddEditSubjectDialog(sub),
                      ),
                      Switch(
                        value: isActive,
                        activeThumbColor: const Color(0xFF2563EB),
                        onChanged: (val) => _toggleStatus(sub['id'], isActive),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
