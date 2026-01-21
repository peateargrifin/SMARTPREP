import re
from youtube_transcript_api import YouTubeTranscriptApi
from urllib.parse import urlparse, parse_qs

class YouTubeProcessor:
    def __init__(self):
        # Create the API instance
        self.yt_api = YouTubeTranscriptApi()

    def extract_video_id(self, url):
        """
        Extract video ID from various YouTube URL formats
        """
        patterns = [
            r'(?:youtube\.com\/watch\?v=|youtu\.be\/)([^&\n?]*)',
            r'youtube\.com\/embed\/([^&\n?]*)',
            r'youtube\.com\/v\/([^&\n?]*)'
        ]

        for pattern in patterns:
            match = re.search(pattern, url)
            if match:
                return match.group(1)

        try:
            parsed_url = urlparse(url)
            video_id = parse_qs(parsed_url.query).get('v')
            if video_id:
                return video_id[0]
        except:
            pass
        return None

    def _extract_text_from_item(self, item):
        """
        Helper to safely get text whether item is a Dict or an Object
        """
        try:
            # Try treating it as an Object (Your specific case)
            return item.text
        except AttributeError:
            # Fallback to Dictionary (Standard case)
            return item['text']

    def get_transcript(self, url):
        """
        Get transcript using the instance method .fetch()
        """
        video_id = self.extract_video_id(url)

        if not video_id:
            print("Error: Invalid YouTube URL")
            return None

        try:
            # Fetch the transcript
            transcript_list = self.yt_api.fetch(video_id)

            # Use the helper to extract text safely
            full_text = " ".join([self._extract_text_from_item(item) for item in transcript_list])
            return self._clean_text(full_text)

        except Exception as e:
            print(f"Direct fetch failed: {e}")

            # Fallback: List available transcripts
            try:
                transcripts = self.yt_api.list(video_id)

                # Try to find English
                try:
                    transcript = transcripts.find_transcript(['en', 'en-US'])
                except:
                    # If no english, just take the first one found
                    transcript = next(iter(transcripts))

                fetched_data = transcript.fetch()
                full_text = " ".join([self._extract_text_from_item(item) for item in fetched_data])
                return self._clean_text(full_text)

            except Exception as e2:
                print(f"Fallback failed: {e2}")
                return None

    def _clean_text(self, text):
        if not text: return ""
        text = text.replace('\n', ' ')
        text = re.sub(r'\s+', ' ', text)
        return text.strip()