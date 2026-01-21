import uuid
from datetime import datetime
from collections import defaultdict
import pandas as pd
import numpy as np

class TestAnalyzer:
    def __init__(self):
        self.test_sessions = {}  # Store test sessions and results
        self.performance_db = []  # Store all test performances for analytics

    def create_test_session(self, document_id, questions):
        """
        Create a new test session
        """
        test_id = str(uuid.uuid4())

        self.test_sessions[test_id] = {
            'test_id': test_id,
            'document_id': document_id,
            'questions': questions,
            'created_at': datetime.now().isoformat(),
            'submitted': False,
            'answers': None,
            'results': None
        }

        return test_id

    def analyze_test(self, test_id, user_answers):
        """
        Analyze test results and generate detailed feedback
        user_answers: list of {question_id, selected_option}
        """
        if test_id not in self.test_sessions:
            raise ValueError("Test session not found")

        session = self.test_sessions[test_id]
        questions = session['questions']

        # Create answer lookup
        answer_lookup = {ans['question_id']: ans['selected_option'] for ans in user_answers}

        # Analyze each question
        results = []
        topic_performance = defaultdict(lambda: {'correct': 0, 'total': 0, 'questions': []})
        difficulty_performance = defaultdict(lambda: {'correct': 0, 'total': 0})

        total_score = 0
        max_score = len(questions)

        for question in questions:
            q_id = question['id']
            correct_answer = question['correct_answer']
            user_answer = answer_lookup.get(q_id)
            topic = question.get('topic', 'General')
            difficulty = question.get('difficulty', 'medium')

            is_correct = (user_answer == correct_answer)

            if is_correct:
                total_score += 1
                topic_performance[topic]['correct'] += 1
                difficulty_performance[difficulty]['correct'] += 1

            topic_performance[topic]['total'] += 1
            topic_performance[topic]['questions'].append({
                'question': question['question'],
                'correct': is_correct,
                'user_answer': user_answer,
                'correct_answer': correct_answer
            })
            difficulty_performance[difficulty]['total'] += 1

            results.append({
                'question_id': q_id,
                'question': question['question'],
                'topic': topic,
                'difficulty': difficulty,
                'user_answer': user_answer,
                'correct_answer': correct_answer,
                'is_correct': is_correct,
                'explanation': question.get('explanation', 'No explanation available')
            })

        # Calculate percentages and categorize performance
        topic_analysis = {}
        for topic, perf in topic_performance.items():
            percentage = (perf['correct'] / perf['total']) * 100

            # Categorize performance level
            if percentage >= 80:
                level = 'Good'
            elif percentage >= 50:
                level = 'Moderate'
            else:
                level = 'Needs Improvement'

            topic_analysis[topic] = {
                'correct': perf['correct'],
                'total': perf['total'],
                'percentage': round(percentage, 2),
                'level': level,
                'questions_detail': perf['questions']
            }

        # Overall performance
        overall_percentage = (total_score / max_score) * 100

        # Store results
        analysis = {
            'test_id': test_id,
            'score': total_score,
            'max_score': max_score,
            'percentage': round(overall_percentage, 2),
            'topic_analysis': topic_analysis,
            'difficulty_breakdown': dict(difficulty_performance),
            'detailed_results': results,
            'weak_areas': self._identify_weak_areas(topic_analysis),
            'recommendations': self._generate_recommendations(topic_analysis),
            'submitted_at': datetime.now().isoformat()
        }

        # Update session
        session['submitted'] = True
        session['answers'] = user_answers
        session['results'] = analysis

        # Store in performance database
        self.performance_db.append({
            'test_id': test_id,
            'timestamp': datetime.now(),
            'score': total_score,
            'max_score': max_score,
            'percentage': overall_percentage,
            'topics': list(topic_analysis.keys())
        })

        return analysis

    def _identify_weak_areas(self, topic_analysis):
        """
        Identify topics that need improvement
        """
        weak_areas = []

        for topic, analysis in topic_analysis.items():
            if analysis['level'] == 'Needs Improvement':
                weak_areas.append({
                    'topic': topic,
                    'percentage': analysis['percentage'],
                    'correct': analysis['correct'],
                    'total': analysis['total']
                })

        # Sort by percentage (worst first)
        weak_areas.sort(key=lambda x: x['percentage'])

        return weak_areas

    def _generate_recommendations(self, topic_analysis):
        """
        Generate personalized study recommendations
        """
        recommendations = []

        for topic, analysis in topic_analysis.items():
            level = analysis['level']
            percentage = analysis['percentage']

            if level == 'Needs Improvement':
                recommendations.append({
                    'topic': topic,
                    'priority': 'High',
                    'message': f"Focus on {topic}. Your current score is {percentage:.1f}%. Review fundamental concepts and practice more questions on this topic."
                })
            elif level == 'Moderate':
                recommendations.append({
                    'topic': topic,
                    'priority': 'Medium',
                    'message': f"Strengthen your understanding of {topic}. You're at {percentage:.1f}%. Review specific areas where you made mistakes."
                })
            else:  # Good
                recommendations.append({
                    'topic': topic,
                    'priority': 'Low',
                    'message': f"Great job on {topic}! You scored {percentage:.1f}%. Continue practicing to maintain proficiency."
                })

        # Sort by priority
        priority_order = {'High': 0, 'Medium': 1, 'Low': 2}
        recommendations.sort(key=lambda x: priority_order[x['priority']])

        return recommendations

    def get_detailed_analysis(self, test_id):
        """
        Retrieve detailed analysis for a test
        """
        if test_id not in self.test_sessions:
            return None

        session = self.test_sessions[test_id]
        return session.get('results')

    def get_performance_trends(self, user_id=None):
        """
        Get performance trends over multiple tests
        """
        if not self.performance_db:
            return None

        df = pd.DataFrame(self.performance_db)

        trends = {
            'average_score': df['percentage'].mean(),
            'tests_taken': len(df),
            'improvement': self._calculate_improvement(df),
            'common_topics': self._find_common_topics(df)
        }

        return trends

    def _calculate_improvement(self, df):
        """
        Calculate improvement over time
        """
        if len(df) < 2:
            return 0

        recent = df.tail(3)['percentage'].mean()
        older = df.head(3)['percentage'].mean()

        return round(recent - older, 2)

    def _find_common_topics(self, df):
        """
        Find most frequently tested topics
        """
        all_topics = []
        for topics in df['topics']:
            all_topics.extend(topics)

        topic_counts = pd.Series(all_topics).value_counts()
        return topic_counts.head(5).to_dict()