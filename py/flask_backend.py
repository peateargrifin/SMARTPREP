from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from werkzeug.utils import secure_filename
import json
from datetime import datetime
from tutoring_agent import TutoringAgent

# Import custom modules
from pdf_processor import PDFProcessor
from youtube_processor import YouTubeProcessor
from rag_agent_module import RAGAgent
from mcq_generator import MCQGenerator
from test_analyser import TestAnalyzer

app = Flask(__name__)
CORS(app)

# Configuration
UPLOAD_FOLDER = 'uploads'
ALLOWED_EXTENSIONS = {'pdf'}
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 50 * 1024 * 1024  # 50MB max file size

# Ensure upload folder exists
os.makedirs(UPLOAD_FOLDER, exist_ok=True)

# Initialize processors
pdf_processor = PDFProcessor()
youtube_processor = YouTubeProcessor()
rag_agent = RAGAgent()
tutoring_agent = TutoringAgent(rag_agent)
mcq_generator = MCQGenerator()
test_analyzer = TestAnalyzer()

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

@app.route('/health', methods=['GET'])
def health_check():
    return jsonify({'status': 'healthy', 'message': 'Server is running'}), 200

@app.route('/upload-pdf', methods=['POST'])
def upload_pdf():
    try:
        if 'file' not in request.files:
            return jsonify({'error': 'No file provided'}), 400

        file = request.files['file']
        if file.filename == '':
            return jsonify({'error': 'No file selected'}), 400

        if file and allowed_file(file.filename):
            filename = secure_filename(file.filename)
            filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
            file.save(filepath)

            # Extract text from PDF
            text_content = pdf_processor.extract_text(filepath)

            # Process with RAG agent
            document_id = rag_agent.process_document(text_content, filename)

            # Extract topics/sections
            topics = rag_agent.extract_topics(text_content)

            return jsonify({
                'success': True,
                'document_id': document_id,
                'filename': filename,
                'topics': topics,
                'text_length': len(text_content)
            }), 200
        else:
            return jsonify({'error': 'Invalid file type'}), 400

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/process-youtube', methods=['POST'])
def process_youtube():
    try:
        data = request.get_json()
        youtube_url = data.get('url')

        if not youtube_url:
            return jsonify({'error': 'No YouTube URL provided'}), 400

        # Extract transcript
        transcript = youtube_processor.get_transcript(youtube_url)

        if not transcript:
            return jsonify({'error': 'Could not extract transcript'}), 400

        # Process with RAG agent
        document_id = rag_agent.process_document(transcript, f"youtube_{youtube_url}")

        # Extract topics
        topics = rag_agent.extract_topics(transcript)

        return jsonify({
            'success': True,
            'document_id': document_id,
            'url': youtube_url,
            'topics': topics,
            'text_length': len(transcript)
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/generate-mcq', methods=['POST'])
def generate_mcq():
    try:
        data = request.get_json()
        document_id = data.get('document_id')
        num_questions = data.get('num_questions', 10)

        if not document_id:
            return jsonify({'error': 'No document ID provided'}), 400

        # Retrieve document content
        document_content = rag_agent.get_document(document_id)

        if not document_content:
            return jsonify({'error': 'Document not found'}), 404

        # Generate MCQs
        mcqs = mcq_generator.generate_questions(document_content, num_questions)

        # Create test session
        test_id = test_analyzer.create_test_session(document_id, mcqs)

        return jsonify({
            'success': True,
            'test_id': test_id,
            'questions': mcqs
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/submit-test', methods=['POST'])
def submit_test():
    try:
        data = request.get_json()
        test_id = data.get('test_id')
        answers = data.get('answers')  # List of {question_id, selected_option}

        if not test_id or not answers:
            return jsonify({'error': 'Missing test ID or answers'}), 400

        # Analyze test results
        results = test_analyzer.analyze_test(test_id, answers)

        return jsonify({
            'success': True,
            'results': results
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/get-analysis/<test_id>', methods=['GET'])
def get_analysis(test_id):
    try:
        analysis = test_analyzer.get_detailed_analysis(test_id)

        if not analysis:
            return jsonify({'error': 'Test not found'}), 404

        return jsonify({
            'success': True,
            'analysis': analysis
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


@app.route('/get-tutoring', methods=['POST'])
def get_tutoring():
    try:
        data = request.get_json()
        document_id = data.get('document_id')
        topic = data.get('topic')

        if not document_id or not topic:
            return jsonify({'error': 'Missing document_id or topic'}), 400

        lesson = tutoring_agent.generate_lesson(document_id, topic)

        return jsonify({
            'success': True,
            'topic': topic,
            'lesson': lesson
        }), 200

    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)