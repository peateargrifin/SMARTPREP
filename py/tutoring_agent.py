import os
import json
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

class TutoringAgent:
    def __init__(self, rag_agent):
        # We need the RAG agent to look up the original textbook content
        self.rag_agent = rag_agent

        # Configure Gemini
        genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))
        self.model = genai.GenerativeModel('gemini-2.5-flash')

    def generate_lesson(self, document_id, weak_topic):
        """
        Creates a personalized lesson for a specific weak topic
        """
        # 1. Retrieve relevant content from the uploaded document about this topic
        relevant_chunks = self.rag_agent.retrieve_relevant_chunks(weak_topic, top_k=4)

        if not relevant_chunks:
            context_text = "No specific context found in document. Using general knowledge."
        else:
            context_text = "\n\n".join([c['text'] for c in relevant_chunks])

        # 2. Ask AI to teach it
        prompt = f"""
        You are an expert personal tutor. The student struggled with the topic: "{weak_topic}".
        
        Using the source material below, create a short, clear, and engaging mini-lesson to help them understand.
        
        Structure the lesson as follows:
        1. **Simple Explanation**: Explain the concept like they are 15 years old.
        2. **Key Points**: Bullet points of the most important facts.
        3. **Common Pitfalls**: What students usually get wrong about this.
        4. **Real World Analogy**: A simple analogy to help remember.

        Source Material:
        {context_text[:10000]}
        """

        try:
            response = self.model.generate_content(prompt)
            return response.text
        except Exception as e:
            return f"Error generating lesson: {str(e)}"