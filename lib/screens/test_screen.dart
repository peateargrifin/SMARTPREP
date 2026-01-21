import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'results_screen.dart';

class TestScreen extends StatefulWidget {
  final String testId;
  final List<dynamic> questions; // Changed to dynamic to handle JSON list safely
  final String documentName;
  final String documentId; // <--- ADDED THIS

  const TestScreen({
    Key? key,
    required this.testId,
    required this.questions,
    required this.documentName,
    required this.documentId, // <--- ADDED THIS
  }) : super(key: key);

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  int _currentQuestionIndex = 0;
  final Map<String, String> _answers = {};
  bool _isSubmitting = false;
  final ApiService _apiService = ApiService(); // Create instance of ApiService

  void _selectAnswer(String questionId, String option) {
    setState(() {
      _answers[questionId] = option;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < widget.questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  Future<void> _submitTest() async {
    // Check if all questions are answered
    final unansweredCount = widget.questions.length - _answers.length;

    if (unansweredCount > 0) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Test'),
          content: Text(
            'You have $unansweredCount unanswered question(s). '
                'Do you want to submit anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Continue Test'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Submit Anyway'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    setState(() => _isSubmitting = true);

    try {
      // Format answers for API
      final answersList = _answers.entries.map((e) {
        return {
          'question_id': e.key,
          'selected_option': e.value,
        };
      }).toList();

      // Call API using the instance variable
      final response = await ApiService.submitTest(widget.testId, answersList);

      if (response['success'] == true) {
        if (!mounted) return; // Check if widget is still on screen

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ResultsScreen(
              // Fix 1: Use response['results'] instead of undefined 'result'
              results: response['results'],
              documentName: widget.documentName,
              // Fix 2: Pass the documentId we added to the top of this file
              documentId: widget.documentId,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Test')),
        body: const Center(child: Text('No questions available')),
      );
    }

    final question = widget.questions[_currentQuestionIndex];
    final questionId = question['id'];
    final selectedAnswer = _answers[questionId];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.documentName),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${_currentQuestionIndex + 1}/${widget.questions.length}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Progress Indicator
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / widget.questions.length,
            backgroundColor: Colors.grey.shade200,
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Question Info
                  Row(
                    children: [
                      if (question['topic'] != null)
                        Chip(
                          label: Text(question['topic']),
                          backgroundColor: Colors.blue.shade50,
                        ),
                      const SizedBox(width: 8),
                      if (question['difficulty'] != null)
                        Chip(
                          label: Text(question['difficulty'].toUpperCase()),
                          backgroundColor: _getDifficultyColor(
                            question['difficulty'],
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Question Text
                  Text(
                    question['question'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Options
                  ...['A', 'B', 'C', 'D'].map((option) {
                    final optionText = question['options'][option];
                    final isSelected = selectedAnswer == option;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildOption(
                        option,
                        optionText,
                        isSelected,
                        questionId,
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ),

          // Navigation Buttons
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentQuestionIndex > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousQuestion,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Previous'),
                    ),
                  ),

                if (_currentQuestionIndex > 0) const SizedBox(width: 16),

                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _currentQuestionIndex == widget.questions.length - 1
                        ? _submitTest
                        : _nextQuestion,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: _currentQuestionIndex == widget.questions.length - 1
                          ? Colors.green
                          : Colors.blue,
                    ),
                    child: Text(
                      _currentQuestionIndex == widget.questions.length - 1
                          ? 'Submit Test'
                          : 'Next',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOption(String option, String text, bool isSelected, String questionId) {
    return GestureDetector(
      onTap: () => _selectAnswer(questionId, option),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Colors.blue : Colors.grey.shade200,
              ),
              child: Center(
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 16,
                  color: isSelected ? Colors.blue.shade900 : Colors.black,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return Colors.green.shade100;
      case 'hard':
        return Colors.red.shade100;
      default:
        return Colors.orange.shade100;
    }
  }
}