import PyPDF2
import pdfplumber
from PIL import Image
import pytesseract
import io

class PDFProcessor:
    def __init__(self):
        self.supported_formats = ['.pdf']

    def extract_text(self, pdf_path):
        """
        Extract text from PDF using multiple methods for robustness
        """
        text = ""

        # Method 1: Try PyPDF2 first (faster)
        try:
            text = self._extract_with_pypdf2(pdf_path)
            if len(text.strip()) > 100:  # If we got substantial text
                return text
        except Exception as e:
            print(f"PyPDF2 extraction failed: {e}")

        # Method 2: Try pdfplumber (better for complex layouts)
        try:
            text = self._extract_with_pdfplumber(pdf_path)
            if len(text.strip()) > 100:
                return text
        except Exception as e:
            print(f"pdfplumber extraction failed: {e}")

        # Method 3: OCR as fallback (for image-based PDFs)
        try:
            text = self._extract_with_ocr(pdf_path)
        except Exception as e:
            print(f"OCR extraction failed: {e}")

        return text

    def _extract_with_pypdf2(self, pdf_path):
        """Extract text using PyPDF2"""
        text = ""
        with open(pdf_path, 'rb') as file:
            pdf_reader = PyPDF2.PdfReader(file)
            for page in pdf_reader.pages:
                text += page.extract_text() + "\n"
        return text

    def _extract_with_pdfplumber(self, pdf_path):
        """Extract text using pdfplumber"""
        text = ""
        with pdfplumber.open(pdf_path) as pdf:
            for page in pdf.pages:
                page_text = page.extract_text()
                if page_text:
                    text += page_text + "\n"
        return text

    def _extract_with_ocr(self, pdf_path):
        """Extract text using OCR (for image-based PDFs)"""
        text = ""
        with pdfplumber.open(pdf_path) as pdf:
            for page in pdf.pages:
                # Convert page to image
                img = page.to_image(resolution=300)
                # Apply OCR
                page_text = pytesseract.image_to_string(img.original)
                text += page_text + "\n"
        return text

    def extract_metadata(self, pdf_path):
        """Extract PDF metadata"""
        try:
            with open(pdf_path, 'rb') as file:
                pdf_reader = PyPDF2.PdfReader(file)
                metadata = pdf_reader.metadata
                return {
                    'title': metadata.get('/Title', 'Unknown'),
                    'author': metadata.get('/Author', 'Unknown'),
                    'pages': len(pdf_reader.pages)
                }
        except Exception as e:
            return {'error': str(e)}

    def chunk_text(self, text, chunk_size=1000, overlap=200):
        """
        Split text into overlapping chunks for better context retention
        """
        words = text.split()
        chunks = []

        for i in range(0, len(words), chunk_size - overlap):
            chunk = ' '.join(words[i:i + chunk_size])
            chunks.append(chunk)

        return chunks