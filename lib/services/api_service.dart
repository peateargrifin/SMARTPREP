import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  // Change this to your Flask server URL
  static const String baseUrl = ''; // For Android Emulator
  // Use 'http://localhost:5000' for iOS simulator
  // Use your computer's IP for physical devices

  // Health check
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Upload PDF
  static Future<Map<String, dynamic>> uploadPDF(File file) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload-pdf'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('file', file.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to upload PDF: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error uploading PDF: $e');
    }
  }

  // Process YouTube URL
  static Future<Map<String, dynamic>> processYouTube(String url) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/process-youtube'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'url': url}),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to process YouTube: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error processing YouTube: $e');
    }
  }

  // Generate MCQ
  static Future<Map<String, dynamic>> generateMCQ(
      String documentId,
      int numQuestions,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/generate-mcq'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'document_id': documentId,
          'num_questions': numQuestions,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to generate MCQ: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error generating MCQ: $e');
    }
  }

  // Submit test
  static Future<Map<String, dynamic>> submitTest(
      String testId,
      List<Map<String, String>> answers,
      ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/submit-test'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'test_id': testId,
          'answers': answers,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit test: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error submitting test: $e');
    }
  }

  // Get analysis
  static Future<Map<String, dynamic>> getAnalysis(String testId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/get-analysis/$testId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to get analysis: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting analysis: $e');
    }
  }


  // Add this inside your ApiService class
  Future<Map<String, dynamic>> getTutoring(String documentId, String topic) async {
    final response = await http.post(
      Uri.parse('$baseUrl/get-tutoring'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'document_id': documentId,
        'topic': topic
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load tutoring lesson');
    }
  }
}