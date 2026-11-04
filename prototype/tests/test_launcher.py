"""Offline routing regression tests; no editor or network required."""
import importlib.util
from pathlib import Path
import unittest
import os
import subprocess
import tempfile
from unittest.mock import patch

spec=importlib.util.spec_from_file_location('launch',Path(__file__).parents[1]/'launch.py')
launch=importlib.util.module_from_spec(spec)
spec.loader.exec_module(launch)

class LauncherTest(unittest.TestCase):
    def test_filenames(self):
        for args,expected in [([], 'rocq'), (['course.v'],'rocq'),
                              (['dir with spaces/course.lean'],'lean'),
                              (['-p','a.lean','b.lean'],'lean'),
                              (['notes.txt','a.lean'],'lean'),
                              (['--','-name.lean'],'lean')]:
            self.assertEqual(launch.select_environment(args),expected)

    def test_options_are_not_filenames(self):
        self.assertEqual(launch.select_environment(['--cmd','foo.lean','a.v']), 'rocq')
        self.assertEqual(launch.select_environment(['-u','config.v','+edit other.v','a.lean']), 'lean')
        self.assertEqual(launch.select_environment(['--listen','sock.v','a.lean']), 'lean')
        with self.assertRaises(ValueError):
            launch.select_environment(['a.v','b.lean'])

    @unittest.skipUnless(os.environ.get('SF_TEST_EDITOR'), 'packaged editor not provided')
    def test_packaged_editors(self):
        nvim=os.environ['SF_TEST_EDITOR']
        with tempfile.TemporaryDirectory() as folder:
            home = Path(folder) / 'home'
            home.mkdir()
            for name,code in [
                ('course file.lean', "assert(vim.bo.filetype=='lean');assert(vim.fn.exists(':LeanInfoviewToggle')==2);assert(vim.fn.exists(':TutorAsk')==2);assert(vim.fn.maparg(' ta','n'):find('TutorAsk',1,true))"),
                ('course file.v', "assert(vim.bo.filetype=='coq');assert(vim.fn.exists(':TutorAsk')==2);assert(vim.fn.exists(':LeanInfoviewToggle')==0)"),
            ]:
                path=Path(folder)/name
                path.write_text('')
                subprocess.run([nvim,'--headless',str(path),'-c','lua local ok,err=pcall(function() '+code+' end); if not ok then print(err); vim.cmd("cquit 1") end','-c','qa!'],
                               env=dict(os.environ,SF_DOC_TEST='1',HOME=str(home)),check=True,timeout=30)
            mixed=subprocess.run([nvim,'a.v','b.lean'],capture_output=True,text=True,timeout=10)
            self.assertEqual(mixed.returncode,2)
            self.assertIn('separate',mixed.stderr)

    def test_exact_argument_preservation(self):
        args=['launcher','--headless','--listen','a socket','+set number','a file.lean']
        with patch.object(launch.sys,'argv',args), patch.object(launch.os,'execv') as run:
            launch.main()
        run.assert_called_once_with('@lean@',['@lean@',*args[1:]])

if __name__=='__main__':
    unittest.main()
