import os
import json
import uuid
import random
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

class MCQGenerator:
    def __init__(self):
        # Configure Gemini
        genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))
        self.model = genai.GenerativeModel('gemini-2.5-flash')

    def generate_questions(self, document_content, num_questions=10):
        """
        Generate MCQ questions using Google Gemini
        """
        text = document_content['full_text']
        chunks = document_content['chunks']

        # Sample text if too long (Gemini 1.5 has huge context, but let's be safe)
        if len(chunks) > 15:
            sampled_chunks = random.sample(chunks, min(15, len(chunks)))
            text_for_generation = '\n\n'.join(sampled_chunks)
        else:
            text_for_generation = text[:30000] # Gemini handles large text easily

        prompt = f"""
        You are an expert educational assessment creator. Generate exactly {num_questions} high-quality multiple choice questions based on the provided content.

        Requirements:
        1. Each question must have 4 options (A, B, C, D).
        2. Cover different topics/sections.
        3. Mix difficulty levels (easy, medium, hard).
        4. Output MUST be valid JSON only, no markdown formatting.

        JSON Structure:
        [
          {{
            "question": "Question text?",
            "options": {{
              "A": "Option 1",
              "B": "Option 2", 
              "C": "Option 3",
              "D": "Option 4"
            }},
            "correct_answer": "B",
            "topic": "Topic Name",
            "difficulty": "medium",
            "explanation": "Explanation here"
          }}
        ]

        Content:
        {text_for_generation}
        """

        try:
            # Force JSON response type
            response = self.model.generate_content(
                prompt,
                generation_config={"response_mime_type": "application/json"}
            )

            content = response.text.strip()

            # Parse JSON
            data = json.loads(content)

            # Handle if wrapped in specific keys
            if isinstance(data, dict):
                # Look for a list inside the dictionary
                for val in data.values():
                    if isinstance(val, list):
                        data = val
                        break
                # If still dict, wrap in list
                if isinstance(data, dict):
                    data = [data]

            # Add UUIDs
            final_questions = []
            for q in data:
                if 'question' in q and 'options' in q:
                    q['id'] = str(uuid.uuid4())
                    final_questions.append(q)

            return final_questions[:num_questions]

        except Exception as e:
            print(f"Error generating questions with Gemini: {e}")
            return self._generate_fallback_questions(num_questions)

    def _generate_fallback_questions(self, num_questions):
        questions = []
        for i in range(num_questions):
            questions.append({
                'id': str(uuid.uuid4()),
                'question': f'Error generating question {i+1}. Please try again.',
                'options': {'A': 'Error', 'B': 'Error', 'C': 'Error', 'D': 'Error'},
                'correct_answer': 'A',
                'topic': 'System',
                'difficulty': 'easy',
                'explanation': 'System error occurred.'
            })
        return questions