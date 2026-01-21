import numpy as np
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import re
import uuid
import os
import json
import google.generativeai as genai
from dotenv import load_dotenv

load_dotenv()

class RAGAgent:
    def __init__(self):
        self.documents = {}
        self.vectorizer = TfidfVectorizer(max_features=500, stop_words='english')
        self.vectors = None
        self.chunk_mapping = {}

        # Configure Gemini
        genai.configure(api_key=os.environ.get("GEMINI_API_KEY"))
        self.model = genai.GenerativeModel('gemini-2.5-flash')

    def process_document(self, text, filename):
        document_id = str(uuid.uuid4())
        chunks = self._chunk_text(text)

        self.documents[document_id] = {
            'filename': filename,
            'full_text': text,
            'chunks': chunks,
            'chunk_count': len(chunks)
        }

        for i, chunk in enumerate(chunks):
            chunk_id = f"{document_id}_{i}"
            self.chunk_mapping[chunk_id] = {
                'document_id': document_id,
                'chunk_index': i,
                'text': chunk
            }

        self._update_vectors()
        return document_id

    def _chunk_text(self, text, chunk_size=1000, overlap=200):
        paragraphs = text.split('\n\n')
        chunks = []
        current_chunk = ""

        for para in paragraphs:
            para = para.strip()
            if not para: continue

            if len(current_chunk) + len(para) > chunk_size and current_chunk:
                chunks.append(current_chunk)
                words = current_chunk.split()
                overlap_text = ' '.join(words[-overlap:]) if len(words) > overlap else current_chunk
                current_chunk = overlap_text + ' ' + para
            else:
                current_chunk += ('\n\n' if current_chunk else '') + para

        if current_chunk:
            chunks.append(current_chunk)
        return chunks

    def _update_vectors(self):
        all_chunks = [info['text'] for info in self.chunk_mapping.values()]
        if all_chunks:
            self.vectors = self.vectorizer.fit_transform(all_chunks)

    def retrieve_relevant_chunks(self, query, top_k=5):
        if not self.chunk_mapping or self.vectors is None:
            return []

        try:
            query_vector = self.vectorizer.transform([query])
            similarities = cosine_similarity(query_vector, self.vectors)[0]
            top_indices = np.argsort(similarities)[-top_k:][::-1]

            chunk_ids = list(self.chunk_mapping.keys())
            relevant_chunks = []

            for idx in top_indices:
                chunk_id = chunk_ids[idx]
                chunk_info = self.chunk_mapping[chunk_id]
                relevant_chunks.append({
                    'text': chunk_info['text'],
                    'similarity': float(similarities[idx]),
                    'document_id': chunk_info['document_id']
                })
            return relevant_chunks
        except:
            return []

    def get_document(self, document_id):
        return self.documents.get(document_id)

    def extract_topics(self, text):
        """
        Extract main topics using Gemini
        """
        try:
            prompt = f"""Analyze this educational content and extract the main topics. 
            Return ONLY a JSON list of strings.
            
            Example: ["Topic A", "Topic B", "Topic C"]
            
            Content:
            {text[:10000]}"""

            response = self.model.generate_content(
                prompt,
                generation_config={"response_mime_type": "application/json"}
            )

            data = json.loads(response.text)

            # Handle {"topics": [...]} or just [...]
            if isinstance(data, dict):
                for val in data.values():
                    if isinstance(val, list):
                        return val
                return list(data.keys())
            return data

        except Exception as e:
            print(f"Topic extraction error: {e}")
            return self._extract_topics_fallback(text)

    def _extract_topics_fallback(self, text):
        headers = re.findall(r'\n([A-Z][A-Za-z\s]+)(?:\n|:)', text)
        if headers:
            topics = list(set([h.strip() for h in headers[:20]]))
            return topics[:10]
        return ["General Overview", "Key Concepts", "Summary"]