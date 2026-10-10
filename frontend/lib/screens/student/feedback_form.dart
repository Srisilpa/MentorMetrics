import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../widgets/star_rating_bar.dart';

class FeedbackForm extends StatefulWidget {
  final VoidCallback? onSubmitted;

  const FeedbackForm({super.key, this.onSubmitted});

  @override
  State<FeedbackForm> createState() => _FeedbackFormState();
}

class _FeedbackFormState extends State<FeedbackForm> {
  final _formKey = GlobalKey<FormState>();
  final _commentsController = TextEditingController();

  List<dynamic> _facultyList = [];
  List<dynamic> _subjectList = [];

  int? _selectedFacultyId;
  int? _selectedSubjectId;
  String? _selectedSubjectName;

  int _teachingQuality = 5;
  int _subjectKnowledge = 5;
  int _communication = 5;
  int _punctuality = 5;
  int _overallSatisfaction = 5;

  bool _loadingData = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadFacultyAndSubjects();
  }

  Future<void> _loadFacultyAndSubjects() async {
    setState(() {
      _loadingData = true;
      _errorMessage = null;
    });

    try {
      final faculty = await ApiService.getFeedbackFaculty();
      setState(() {
        _facultyList = faculty;
        _loadingData = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
          _loadingData = false;
        });
      }
    }
  }

  void _onFacultyChanged(int? facultyId) {
    setState(() {
      _selectedFacultyId = facultyId;
      _selectedSubjectId = null;
      _selectedSubjectName = null;
      _subjectList = [];

      if (facultyId != null) {
        final fac = _facultyList.firstWhere(
          (f) => f['id'] == facultyId,
          orElse: () => null,
        );
        if (fac != null && fac['subjects'] != null) {
          _subjectList = List.from(fac['subjects']);
          if (_subjectList.isNotEmpty) {
            _selectedSubjectId = _subjectList.first['id'];
            _selectedSubjectName = _subjectList.first['subject_name'];
          }
        }
      }
    });
  }

  void _resetForm() {
    setState(() {
      _selectedFacultyId = null;
      _selectedSubjectId = null;
      _selectedSubjectName = null;
      _subjectList = [];
      _teachingQuality = 5;
      _subjectKnowledge = 5;
      _communication = 5;
      _punctuality = 5;
      _overallSatisfaction = 5;
      _commentsController.clear();
      _errorMessage = null;
    });
  }

  Future<void> _handleSubmit() async {
    if (_selectedFacultyId == null) {
      setState(() => _errorMessage = 'Please select a faculty member.');
      return;
    }

    if (_selectedSubjectId == null && (_selectedSubjectName == null || _selectedSubjectName!.isEmpty)) {
      setState(() => _errorMessage = 'Please select a subject for this faculty member.');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessage = null;
    });

    try {
      final result = await ApiService.submitFeedback(
        facultyId: _selectedFacultyId!,
        subjectId: _selectedSubjectId ?? 0,
        subjectName: _selectedSubjectName ?? 'General',
        teachingQuality: _teachingQuality,
        subjectKnowledge: _subjectKnowledge,
        communication: _communication,
        punctuality: _punctuality,
        overallSatisfaction: _overallSatisfaction,
        comments: _commentsController.text.trim(),
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.green, size: 28),
              SizedBox(width: 10),
              Text('Feedback Submitted'),
            ],
          ),
          content: Text(
            result['message'] ?? 'Thank you! Your feedback has been recorded securely.',
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetForm();
                widget.onSubmitted?.call();
              },
              child: const Text('View Submission History'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingData) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading active faculty and course details...'),
            ],
          ),
        ),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(45),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.rate_review_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Faculty Performance Feedback',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Your feedback is strictly confidential and aids continuous academic improvement.',
                        style: TextStyle(
                          color: Color(0xFFE0E7FF),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Error message banner
          if (_errorMessage != null) ...[
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
          ],

          // 1. Faculty Selection Card
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.person_rounded, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Text(
                        '1. Select Faculty Member',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_facultyList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text('No active faculty members are currently available.'),
                    )
                  else
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Faculty Member',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.badge_outlined),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedFacultyId,
                          isDense: true,
                          isExpanded: true,
                          hint: const Text('Choose a faculty member...'),
                          items: _facultyList.map((f) {
                            return DropdownMenuItem<int>(
                              value: f['id'] as int,
                              child: Text(
                                '${f['name']} (${f['department']} - ${f['designation']})',
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                          onChanged: _onFacultyChanged,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 2. Subject Selection Card
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.menu_book_rounded, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Text(
                        '2. Select Associated Subject',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_selectedFacultyId == null)
                    const Text(
                      'Please select a faculty member above to view their courses.',
                      style: TextStyle(color: Colors.blueGrey, fontSize: 13),
                    )
                  else if (_subjectList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'No specific subjects mapped to this faculty. Please ask administrator to assign courses.',
                        style: TextStyle(color: Colors.orange, fontSize: 13),
                      ),
                    )
                  else
                    InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Subject / Course',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.book_outlined),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: _selectedSubjectId,
                          isDense: true,
                          isExpanded: true,
                          items: _subjectList.map((s) {
                            final code = s['subject_code'] ?? '';
                            final name = s['subject_name'] ?? '';
                            return DropdownMenuItem<int>(
                              value: s['id'] as int,
                              child: Text('$code: $name', overflow: TextOverflow.ellipsis),
                            );
                          }).toList(),
                          onChanged: (id) {
                            setState(() {
                              _selectedSubjectId = id;
                              final match = _subjectList.firstWhere(
                                (s) => s['id'] == id,
                                orElse: () => null,
                              );
                              _selectedSubjectName = match != null ? match['subject_name'] : null;
                            });
                          },
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 3. Evaluation Criteria
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Text(
              '3. Performance Evaluation Criteria (1 to 5 Stars)',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0F172A),
              ),
            ),
          ),

          StarRatingBar(
            title: '1. Teaching Quality & Pedagogy',
            subtitle: 'Clarity of concept explanations, real-world examples, and problem-solving.',
            rating: _teachingQuality,
            onRatingChanged: (val) => setState(() => _teachingQuality = val),
          ),

          StarRatingBar(
            title: '2. Subject Knowledge & Depth',
            subtitle: 'Domain expertise, mastery over syllabus, and ability to answer challenging questions.',
            rating: _subjectKnowledge,
            onRatingChanged: (val) => setState(() => _subjectKnowledge = val),
          ),

          StarRatingBar(
            title: '3. Communication & Classroom Interaction',
            subtitle: 'Clarity, audibility, approachable demeanor, and student engagement.',
            rating: _communication,
            onRatingChanged: (val) => setState(() => _communication = val),
          ),

          StarRatingBar(
            title: '4. Punctuality & Organization',
            subtitle: 'Regularity in conducting scheduled lectures, labs, and adherence to timetable.',
            rating: _punctuality,
            onRatingChanged: (val) => setState(() => _punctuality = val),
          ),

          StarRatingBar(
            title: '5. Overall Satisfaction & Mentorship',
            subtitle: 'Overall learning experience, guidance, and academic mentorship provided.',
            rating: _overallSatisfaction,
            onRatingChanged: (val) => setState(() => _overallSatisfaction = val),
          ),

          const SizedBox(height: 16),

          // 4. Written Comments
          Card(
            elevation: 0,
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.comment_outlined, color: Color(0xFF2563EB)),
                      SizedBox(width: 8),
                      Text(
                        '4. Constructive Comments (Optional)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _commentsController,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: const InputDecoration(
                      hintText: 'Share any positive highlights, areas for improvement, or constructive feedback for the mentor...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Actions
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: _submitting ? null : _resetForm,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reset Form'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _submitting ? null : _handleSubmit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_submitting ? 'Submitting Feedback...' : 'Submit Feedback'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
