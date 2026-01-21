import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; // Ensure you have this pkg
import '../services/api_service.dart';

class TutoringScreen extends StatefulWidget {
  final String documentId;
  final String topic;

  const TutoringScreen({
    Key? key,
    required this.documentId,
    required this.topic
  }) : super(key: key);

  @override
  State<TutoringScreen> createState() => _TutoringScreenState();
}

class _TutoringScreenState extends State<TutoringScreen> {
  final ApiService _apiService = ApiService();
  String _lessonContent = '';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLesson();
  }

  Future<void> _fetchLesson() async {
    try {
      final result = await _apiService.getTutoring(widget.documentId, widget.topic);
      setState(() {
        _lessonContent = result['lesson'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _lessonContent = "Error loading lesson. Please try again.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tutor: ${widget.topic}'),
        backgroundColor: Colors.teal,
      ),
      body: _isLoading
          ? const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.teal),
            SizedBox(height: 20),
            Text("AI Tutor is preparing your lesson..."),
          ],
        ),
      )
          : Container(
        color: Colors.teal.shade50,
        child: Markdown(
          data: _lessonContent,
          styleSheet: MarkdownStyleSheet(
            h1: const TextStyle(color: Colors.teal, fontSize: 24, fontWeight: FontWeight.bold),
            h2: const TextStyle(color: Colors.teal, fontSize: 20, fontWeight: FontWeight.bold),
            p: const TextStyle(fontSize: 16, height: 1.5),
            strong: const TextStyle(color: Colors.deepOrange),
            blockSpacing: 15.0,
          ),
          padding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}