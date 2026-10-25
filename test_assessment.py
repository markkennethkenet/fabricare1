import unittest
from datetime import date
from assessment import severity_for, score_for, grade_for, assess, normalize_user_inputs

class AssessmentTests(unittest.TestCase):
    def test_severity_boundaries(self):
        for area, expected in [(0, 'minor'), (.0199, 'minor'), (.02, 'moderate'), (.08, 'moderate'), (.0801, 'severe')]:
            self.assertEqual(severity_for(area), expected)

    def test_score_and_grade(self):
        self.assertEqual(score_for([]), 100)
        self.assertEqual(score_for([{'type': 'hole', 'severity': 'severe'}]), 70)
        self.assertEqual(score_for([{'type': 'future_class', 'severity': 'minor'}]), 95)
        self.assertEqual(score_for([{'type': 'hole', 'severity': 'severe'}] * 10), 0)
        self.assertEqual(grade_for(90), 'Excellent')
        self.assertEqual(grade_for(89), 'Good')
        self.assertEqual(grade_for(75), 'Good')
        self.assertEqual(grade_for(50), 'Fair')
        self.assertEqual(grade_for(49), 'Poor')

    def test_lifespan_baseline(self):
        healthy = assess('cotton', [])
        damaged = assess('cotton', [{'type': 'hole', 'severity': 'severe'}])
        self.assertLess(damaged['estimated_remaining_months'], healthy['estimated_remaining_months'])
        self.assertEqual(healthy['estimate_method'], 'rule_based_not_validated')

    def test_use_washing_and_age_reduce_remaining_life(self):
        today = date(2026, 10, 20)
        base = {'condition': 'previously_used', 'use_frequency': 'weekly', 'washing_frequency': 'weekly'}
        baseline = assess('cotton', [], base, today=today)
        heavy = assess('cotton', [], {**base, 'use_frequency': 'daily', 'washing_frequency': 'multiple_per_week'}, today=today)
        older = assess('cotton', [], {**base, 'purchase_date': '2025-10-20'}, today=today)
        self.assertLess(heavy['estimated_remaining_months'], baseline['estimated_remaining_months'])
        self.assertLess(older['estimated_remaining_months'], baseline['estimated_remaining_months'])
        self.assertLess(heavy['projected_condition_after_6_months']['health_score'], baseline['projected_condition_after_6_months']['health_score'])
        self.assertIn('previously used', baseline['usage_status'])

    def test_severity_affects_lifespan_and_projection_even_at_same_score(self):
        inputs = normalize_user_inputs({'condition': 'new'})
        from assessment import lifespan_for
        minor = lifespan_for('cotton', 80, [{'severity': 'minor'}], inputs)
        severe = lifespan_for('cotton', 80, [{'severity': 'severe'}], inputs)
        self.assertLess(severe['estimated_remaining_months'], minor['estimated_remaining_months'])
        self.assertLess(severe['projected_condition_after_6_months']['health_score'], minor['projected_condition_after_6_months']['health_score'])

    def test_lifespan_is_bounded_and_uses_fabric_configuration(self):
        inputs = {'condition': 'previously_used', 'purchase_date': '1900-01-01'}
        result = assess('future_fabric', [], inputs, today=date(2026, 10, 20))
        self.assertEqual(result['estimated_remaining_months'], 0)
        self.assertGreaterEqual(result['projected_condition_after_6_months']['health_score'], 0)
        self.assertGreater(assess('denim', [])['estimated_remaining_months'], assess('cotton', [])['estimated_remaining_months'])

    def test_history_validation_known_unknown_and_future_dates(self):
        today = date(2026, 10, 20)
        for inputs in [[], {'condition': 'invalid'}, {'use_frequency': []},
                       {'condition': 'previously_used', 'purchase_date_known': True},
                       {'purchase_date': '2027-01-01'}, {'purchase_date': 'bad-date'},
                       {'purchase_date_known': 'yes'}]:
            with self.assertRaises(ValueError):
                normalize_user_inputs(inputs, today=today)
        unknown = normalize_user_inputs({'condition': 'previously_used', 'purchase_date_known': False}, today=today)
        self.assertIsNone(unknown['purchase_date'])

if __name__ == '__main__':
    unittest.main()
