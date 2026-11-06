"""Offline checks of edit validation and incremental prompt construction."""
import importlib.util
import json
from pathlib import Path
import unittest
from unittest.mock import Mock, patch

spec = importlib.util.spec_from_file_location('tutor', Path(__file__).parents[1] / 'tutor.py')
tutor = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tutor)

class TutorTest(unittest.TestCase):
    def test_account_default_is_explicit_and_pagination_is_followed(self):
        client = tutor.Codex.__new__(tutor.Codex)
        client.rpc = Mock(side_effect=[
            {'data': [{'model': 'available'}], 'nextCursor': 'next'},
            {'data': [{'model': 'account-default', 'isDefault': True}]},
            {'thread': {'id': 'thread'}},
        ])
        with patch.dict(tutor.os.environ, {'SF_TUTOR_MODEL': ''}):
            self.assertEqual(client.start('/tmp'), 'thread')
        self.assertEqual(client.rpc.call_args_list[1].args[1]['cursor'], 'next')
        self.assertEqual(client.rpc.call_args.args[1]['model'], 'account-default')

    def test_explicit_override_skips_catalog(self):
        client = tutor.Codex.__new__(tutor.Codex)
        client.rpc = Mock(return_value={'thread': {'id': 'thread'}})
        with patch.dict(tutor.os.environ, {'SF_TUTOR_MODEL': ' custom-model '}):
            client.start('/tmp')
        client.rpc.assert_called_once()
        self.assertEqual(client.rpc.call_args.args[1]['model'], 'custom-model')

    def test_missing_default_uses_visible_text_model_and_empty_catalog_fails(self):
        client = tutor.Codex.__new__(tutor.Codex)
        with patch.dict(tutor.os.environ, {'SF_TUTOR_MODEL': ''}):
            client.rpc = Mock(return_value={'data': [
                {'model': 'hidden', 'hidden': True, 'isDefault': True},
                {'model': 'audio', 'inputModalities': ['audio']},
                {'model': 'available'},
            ]})
            self.assertEqual(client.model(), 'available')
            client.rpc = Mock(return_value={'data': []})
            with self.assertRaisesRegex(RuntimeError, 'no available text models'):
                client.start('/tmp')
            self.assertEqual(client.rpc.call_count, 1)

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
