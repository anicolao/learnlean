"""Offline checks of edit validation and incremental prompt construction."""
import importlib.util
import json
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('tutor', Path(__file__).parents[1] / 'tutor.py')
tutor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tutor)

class TutorTest(unittest.TestCase):
    def test_unicode_and_sequential_edits(self):
        response = {'edits': [{'old': 'α', 'new': 'β'}, {'old': '', 'new': '\n(** Exercise *)\n'}]}
        self.assertEqual(tutor.apply_edits('Check α.\n', response), 'Check β.\n\n(** Exercise *)\n')

    def test_ambiguous_missing_noop_and_multiple_appends(self):
        for edits in [[{'old': 'a', 'new': 'b'}], [{'old': 'z', 'new': 'b'}], [],
                      [{'old': '', 'new': 'x'}, {'old': '', 'new': 'y'}]]:
            with self.assertRaises(ValueError):
                tutor.apply_edits('a a', {'edits': edits})

    def test_full_then_diff_from_accepted_file(self):
        request = {'language': 'Lean 4', 'path': '/tmp/course.lean', 'prompt': 'Why?', 'example': 'reference'}
        first = json.loads(tutor.context('def α := 1\n', None, request))
        self.assertEqual(first['full_file'], 'def α := 1\n')
        self.assertEqual(first['reference_example'], 'reference')
        later = json.loads(tutor.context('def α := 2\n', 'def α := 1\n', request))
        self.assertNotIn('full_file', later)
        self.assertNotIn('reference_example', later)
        self.assertIn('-def α := 1', later['diff_since_accepted_edits'])
        self.assertIn('+def α := 2', later['diff_since_accepted_edits'])

if __name__ == '__main__':
    unittest.main()
