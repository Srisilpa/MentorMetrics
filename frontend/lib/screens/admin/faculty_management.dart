import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class FacultyManagementScreen extends StatefulWidget {
  const FacultyManagementScreen({super.key});

  @override
  State<FacultyManagementScreen> createState() => _FacultyManagementScreenState();
}

class _FacultyManagementScreenState extends State<FacultyManagementScreen> {
  List<dynamic> _faculty = [];
  List<dynamic> _departments = [];
  List<dynamic> _allSubjects = [];
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
      final fac = await ApiService.getFaculty(activeOnly: false);
      final depts = await ApiService.getDepartments();
      final subs = await ApiService.getSubjects(activeOnly: true);

      if (mounted) {
        setState(() {
          _faculty = fac;
          _departments = depts;
          _allSubjects = subs;
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
      await ApiService.updateFacultyStatus(id, !currentStatus);
      await _loadData();
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              !currentStatus ? 'Faculty member activated.' : 'Faculty member deactivated.',
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

  void _showAddEditFacultyDialog([Map<String, dynamic>? item]) {
    final isEdit = item != null;
    final nameCtrl = TextEditingController(text: item?['name'] ?? '');
    final emailCtrl = TextEditingController(text: item?['email'] ?? '');
    final desigCtrl = TextEditingController(text: item?['designation'] ?? 'Assistant Professor');
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
            title: Text(isEdit ? 'Edit Faculty Details' : 'Add New Faculty Member'),
            content: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Institutional Email *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email_outlined),
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
                    DropdownButtonFormField<String>(
                      initialValue: desigCtrl.text.isNotEmpty ? desigCtrl.text : 'Assistant Professor',
                      decoration: const InputDecoration(
                        labelText: 'Designation *',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Professor & HOD', child: Text('Professor & HOD')),
                        DropdownMenuItem(value: 'Professor', child: Text('Professor')),
                        DropdownMenuItem(value: 'Associate Professor', child: Text('Associate Professor')),
                        DropdownMenuItem(value: 'Assistant Professor', child: Text('Assistant Professor')),
                        DropdownMenuItem(value: 'Visiting Faculty', child: Text('Visiting Faculty')),
                      ],
                      onChanged: (val) {
                        if (val != null) setModalState(() => desigCtrl.text = val);
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final name = nameCtrl.text.trim();
                  final email = emailCtrl.text.trim();
                  final desig = desigCtrl.text.trim();

                  if (name.isEmpty || desig.isEmpty) {
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Name and designation are required.')),
                    );
                    return;
                  }

                  try {
                    if (isEdit) {
                      await ApiService.updateFaculty(item['id'], {
                        'name': name,
                        'email': email.isNotEmpty ? email : null,
                        'department_id': selectedDeptId,
                        'designation': desig,
                      });
                    } else {
                      await ApiService.createFaculty({
                        'name': name,
                        'email': email.isNotEmpty ? email : null,
                        'department_id': selectedDeptId,
                        'designation': desig,
                        'is_active': true,
                      });
                    }

                    if (mounted) {
                      nav.pop();
                      _loadData();
                      messenger.showSnackBar(
                        SnackBar(content: Text(isEdit ? 'Faculty updated.' : 'Faculty added successfully.')),
                      );
                    }
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
                    );
                  }
                },
                child: Text(isEdit ? 'Save Changes' : 'Add Faculty'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAssignSubjectDialog(Map<String, dynamic> fac) {
    int? selectedSubId = _allSubjects.isNotEmpty ? _allSubjects.first['id'] : null;
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final assigned = (fac['subjects'] as List<dynamic>?) ?? [];

          return AlertDialog(
            title: Text('Assign Subjects to ${fac['name']}'),
            content: SizedBox(
              width: 500,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Currently Assigned Courses:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  if (assigned.isEmpty)
                    const Text('No courses assigned yet.', style: TextStyle(color: Colors.blueGrey, fontSize: 12))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: assigned.map((s) {
                        return Chip(
                          label: Text('${s['subject_code']}: ${s['subject_name']}', style: const TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () async {
                            try {
                              await ApiService.unassignSubjectFromFaculty(fac['id'], s['id']);
                              nav.pop();
                              _loadData();
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                  const Divider(height: 32),
                  const Text('Assign New Course:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<int>(
                    initialValue: selectedSubId,
                    decoration: const InputDecoration(
                      labelText: 'Select Course',
                      border: OutlineInputBorder(),
                    ),
                    items: _allSubjects.map((s) {
                      return DropdownMenuItem<int>(
                        value: s['id'] as int,
                        child: Text('${s['subject_code']} - ${s['subject_name']}', overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (val) => setModalState(() => selectedSubId = val),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
              ElevatedButton(
                onPressed: () async {
                  if (selectedSubId == null) return;
                  try {
                    await ApiService.assignSubjectToFaculty(fac['id'], selectedSubId!);
                    nav.pop();
                    _loadData();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Course assigned successfully.')),
                    );
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error: ${e.toString().replaceFirst('Exception: ', '')}')),
                    );
                  }
                },
                child: const Text('Assign Course'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _faculty.where((f) {
      final name = (f['name'] ?? '').toString().toLowerCase();
      final dept = (f['department'] ?? '').toString().toLowerCase();
      final email = (f['email'] ?? '').toString().toLowerCase();
      final matchQuery = name.contains(_searchQuery.toLowerCase()) ||
          dept.contains(_searchQuery.toLowerCase()) ||
          email.contains(_searchQuery.toLowerCase());
      final matchDept = _filterDeptId == null || f['department_id'] == _filterDeptId;
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
                  'Faculty Directory & Management',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                ),
                SizedBox(height: 4),
                Text('Add, edit, activate/deactivate, and assign courses to professors.',
                    style: TextStyle(color: Colors.blueGrey, fontSize: 13)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: () => _showAddEditFacultyDialog(),
              icon: const Icon(Icons.person_add_rounded),
              label: const Text('Add Faculty'),
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
                      hintText: 'Search faculty by name, department, or email...',
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
                  const Icon(Icons.people_outline_rounded, size: 56, color: Colors.blueGrey),
                  const SizedBox(height: 12),
                  const Text('No faculty members found.', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Try adjusting your search filter or add a new faculty member.',
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
              final fac = filtered[index];
              final bool isActive = fac['is_active'] == true;
              final subjects = (fac['subjects'] as List<dynamic>?) ?? [];

              return Card(
                elevation: 0,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isActive ? const Color(0xFFE2E8F0) : Colors.red.shade100,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: isActive ? const Color(0xFFEFF6FF) : Colors.grey.shade200,
                        child: Text(
                          (fac['name'] ?? 'F')[0],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
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
                                  fac['name'] ?? '',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
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
                              '${fac['department']} • ${fac['designation']}',
                              style: TextStyle(fontSize: 13, color: Colors.blueGrey.shade700),
                            ),
                            if (fac['email'] != null) ...[
                              const SizedBox(height: 2),
                              Text(fac['email'], style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                            ],
                            const SizedBox(height: 10),

                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                ...subjects.map((s) => Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${s['subject_code']}: ${s['subject_name']}',
                                        style: const TextStyle(fontSize: 11, color: Color(0xFF334155)),
                                      ),
                                    )),
                                InkWell(
                                  onTap: () => _showAssignSubjectDialog(fac),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF6FF),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFBFDBFE)),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.add, size: 12, color: Color(0xFF2563EB)),
                                        SizedBox(width: 4),
                                        Text('Assign Subject', style: TextStyle(fontSize: 11, color: Color(0xFF2563EB))),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            tooltip: 'Edit details',
                            icon: const Icon(Icons.edit_outlined, color: Colors.blueGrey),
                            onPressed: () => _showAddEditFacultyDialog(fac),
                          ),
                          Switch(
                            value: isActive,
                            activeThumbColor: const Color(0xFF2563EB),
                            onChanged: (val) => _toggleStatus(fac['id'], isActive),
                          ),
                        ],
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
