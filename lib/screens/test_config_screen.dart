// import 'package:flutter/material.dart';
// import '../services/api_service.dart';
// import 'test_screen.dart';
//
// class TestConfigScreen extends StatefulWidget {
//   final String documentId;
//   final String documentName;
//   final List<String> topics;
//
//   const TestConfigScreen({
//     Key? key,
//     required this.documentId,
//     required this.documentName,
//     required this.topics,
//   }) : super(key: key);
//
//   @override
//   State<TestConfigScreen> createState() => _TestConfigScreenState();
// }
//
// class _TestConfigScreenState extends State<TestConfigScreen> {
//   int _selectedQuestionCount = 10;
//   bool _isGenerating = false;
//
//   Future<void> _generateTest() async {
//     setState(() => _isGenerating = true);
//
//     try {
//       final response = await ApiService.generateMCQ(
//         widget.documentId,
//         _selectedQuestionCount,
//       );
//
//       if (response['success'] == true) {
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => TestScreen(
//               testId: response['test_id'],
//               questions: List<Map<String, dynamic>>.from(response['questions']),
//               documentName: widget.documentName,
//             ),
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Error generating test: $e'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     } finally {
//       setState(() => _isGenerating = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Configure Test'),
//       ),
//       body: _isGenerating
//           ? Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: const [
//             CircularProgressIndicator(),
//             SizedBox(height: 24),
//             Text(
//               'Generating questions...',
//               style: TextStyle(fontSize: 18),
//             ),
//             SizedBox(height: 8),
//             Text(
//               'This may take a moment',
//               style: TextStyle(color: Colors.grey),
//             ),
//           ],
//         ),
//       )
//           : SingleChildScrollView(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.stretch,
//           children: [
//             // Document Info Card
//             Card(
//               color: Colors.blue.shade50,
//               child: Padding(
//                 padding: const EdgeInsets.all(20),
//                 child: Column(
//                   children: [
//                     const Icon(
//                       Icons.description,
//                       size: 48,
//                       color: Colors.blue,
//                     ),
//                     const SizedBox(height: 12),
//                     Text(
//                       widget.documentName,
//                       style: const TextStyle(
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                       textAlign: TextAlign.center,
//                     ),
//                     const SizedBox(height: 8),
//                     Text(
//                       '${widget.topics.length} topics identified',
//                       style: const TextStyle(color: Colors.grey),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//
//             const SizedBox(height: 32),
//
//             // Topics Section
//             if (widget.topics.isNotEmpty) ...[
//               const Text(
//                 'Topics Covered:',
//                 style: TextStyle(
//                   fontSize: 18,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),
//               const SizedBox(height: 12),
//               Wrap(
//                 spacing: 8,
//                 runSpacing: 8,
//                 children: widget.topics.map((topic) {
//                   return Chip(
//                     label: Text(topic),
//                     backgroundColor: Colors.purple.shade50,
//                     labelStyle: TextStyle(color: Colors.purple.shade700),
//                   );
//                 }).toList(),
//               ),
//               const SizedBox(height: 32),
//             ],
//
//             // Question Count Selection
//             const Text(
//               'Number of Questions:',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//             const SizedBox(height: 16),
//
//             _buildQuestionOption(10),
//             const SizedBox(height: 12),
//             _buildQuestionOption(15),
//             const SizedBox(height: 12),
//             _buildQuestionOption(20),
//
//             const SizedBox(height: 32),
//
//             // Info Card
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.amber.shade50,
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: Colors.amber.shade200),
//               ),
//               child: Row(
//                 children: const [
//                   Icon(Icons.info_outline, color: Colors.amber),
//                   SizedBox(width: 12),
//                   Expanded(
//                     child: Text(
//                       'AI will generate questions covering all identified topics',
//                       style: TextStyle(fontSize: 14),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 32),
//
//             // Generate Button
//             ElevatedButton.icon(
//               onPressed: _generateTest,
//               icon: const Icon(Icons.auto_awesome),
//               label: Text(
//                 'Generate $_selectedQuestionCount Questions',
//                 style: const TextStyle(fontSize: 16),
//               ),
//               style: ElevatedButton.styleFrom(
//                 padding: const EdgeInsets.symmetric(vertical: 20),
//                 backgroundColor: Colors.green,
//                 shape: RoundedRectangleBorder(
//                   borderRadius: BorderRadius.circular(16),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuestionOption(int count) {
//     final isSelected = _selectedQuestionCount == count;
//
//     return GestureDetector(
//       onTap: () {
//         setState(() => _selectedQuestionCount = count);
//       },
//       child: Container(
//         padding: const EdgeInsets.all(20),
//         decoration: BoxDecoration(
//           color: isSelected ? Colors.blue.shade50 : Colors.white,
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(
//             color: isSelected ? Colors.blue : Colors.grey.shade300,
//             width: 2,
//           ),
//         ),
//         child: Row(
//           children: [
//             Icon(
//               isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
//               color: isSelected ? Colors.blue : Colors.grey,
//             ),
//             const SizedBox(width: 16),
//             Text(
//               '$count Questions',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//                 color: isSelected ? Colors.blue : Colors.black,
//               ),
//             ),
//             const Spacer(),
//             Text(
//               '≈ ${count * 2} minutes',
//               style: TextStyle(
//                 color: Colors.grey.shade600,
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'test_screen.dart';

class TestConfigScreen extends StatefulWidget {
  final String documentId;
  final String documentName;
  final List<dynamic> topics; // Changed to dynamic to handle JSON list safely

  const TestConfigScreen({
    Key? key,
    required this.documentId,
    required this.documentName,
    required this.topics,
  }) : super(key: key);

  @override
  State<TestConfigScreen> createState() => _TestConfigScreenState();
}

class _TestConfigScreenState extends State<TestConfigScreen> {
  int _questionCount = 10;
  bool _isLoading = false;
  final ApiService _apiService = ApiService(); // Create instance

  Future<void> _startTest() async {
    setState(() => _isLoading = true);

    try {
      // Use the instance method generateMcq
      final response = await ApiService.generateMCQ(
        widget.documentId,
        _questionCount,
      );

      if (response['success'] == true) {
        if (!mounted) return;

        // Navigate to Test Screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => TestScreen(
              testId: response['test_id'],
              questions: List<Map<String, dynamic>>.from(response['questions']),
              documentName: widget.documentName,
              // THIS IS THE FIX: Passing the documentId
              documentId: widget.documentId,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating test: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configure Test')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Document Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Icon(Icons.description, size: 48, color: Colors.blue),
                    const SizedBox(height: 16),
                    Text(
                      widget.documentName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Topics List
            const Text(
              'Identified Topics:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: widget.topics.length,
                itemBuilder: (context, index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.topic, color: Colors.blue),
                      title: Text(widget.topics[index].toString()),
                      dense: true,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),

            // Question Count Selector
            const Text(
              'Number of Questions:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 5, label: Text('5')),
                ButtonSegment(value: 10, label: Text('10')),
                ButtonSegment(value: 15, label: Text('15')),
                ButtonSegment(value: 20, label: Text('20')),
              ],
              selected: {_questionCount},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() {
                  _questionCount = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 32),

            // Start Button
            ElevatedButton(
              onPressed: _isLoading ? null : _startTest,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Text(
                'Generate Test',
                style: TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}