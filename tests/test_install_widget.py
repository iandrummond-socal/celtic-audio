import importlib.machinery
import importlib.util
import json
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
loader = importlib.machinery.SourceFileLoader('widget_installer', str(ROOT / 'bin/install-widget'))
spec = importlib.util.spec_from_loader(loader.name, loader)
widget = importlib.util.module_from_spec(spec)
loader.exec_module(widget)


class WidgetInstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.home = Path(self.temp.name)
        self.shell = self.home / 'omarchy/shell.json'
        self.shell.parent.mkdir()
        self.original = {'idle': {'lock': 777}, 'bar': {'layout': {
            'left': [{'id': 'omarchy.menu'}],
            'centerEnd': [{'id': 'omarchy.elsewhen', 'cities': [{'name': 'London'}]},
                          {'id': 'omarchy.weather'}]}}}
        self.shell.write_text(json.dumps(self.original))
        self.source = ROOT / 'omarchy' / widget.WIDGET

    def read(self):
        return json.loads(self.shell.read_text())

    def test_install_preserves_settings_and_backs_up(self):
        backup = widget.install(self.home, self.source)
        self.assertEqual(json.loads((backup / 'shell.json').read_text()), self.original)
        result = self.read()
        self.assertEqual(result['idle'], self.original['idle'])
        entries = result['bar']['layout']['centerEnd']
        self.assertEqual(entries[0], self.original['bar']['layout']['centerEnd'][0])
        self.assertEqual(entries[1], {'id': widget.WIDGET})
        self.assertEqual(entries[2], {'id': 'omarchy.weather'})
        self.assertTrue((self.home / 'omarchy/plugins' / widget.WIDGET / 'BarWidget.qml').is_file())

    def test_repeat_install_has_one_entry_and_preserves_widget_backup(self):
        widget.install(self.home, self.source)
        custom = self.home / 'omarchy/plugins' / widget.WIDGET / 'custom.txt'
        custom.write_text('my customization')
        backup = widget.install(self.home, self.source)
        ids = [widget.entry_id(e) for e in self.read()['bar']['layout']['centerEnd']]
        self.assertEqual(ids.count(widget.WIDGET), 1)
        self.assertEqual((backup / widget.WIDGET / 'custom.txt').read_text(), 'my customization')

    def test_remove_preserves_other_settings(self):
        widget.install(self.home, self.source)
        widget.install(self.home, self.source, remove=True)
        self.assertEqual(self.read(), self.original)
        self.assertFalse((self.home / 'omarchy/plugins' / widget.WIDGET).exists())

    def test_invalid_json_is_untouched(self):
        self.shell.write_text('{broken')
        with self.assertRaises(ValueError):
            widget.install(self.home, self.source)
        self.assertEqual(self.shell.read_text(), '{broken')
        self.assertFalse((self.home / 'omarchy/plugins').exists())

    def test_missing_source_is_untouched(self):
        before = self.shell.read_text()
        with self.assertRaises(OSError):
            widget.install(self.home, self.home / 'missing')
        self.assertEqual(self.shell.read_text(), before)

    def test_absent_world_clock_uses_center_end(self):
        result = widget.configure({'bar': {'layout': {'right': [{'id': 'omarchy.audio'}]}}})
        self.assertEqual(result['bar']['layout']['centerEnd'], [{'id': widget.WIDGET}])
        self.assertEqual(result['bar']['layout']['right'], [{'id': 'omarchy.audio'}])

    def test_moves_existing_entry_and_enables_only_this_widget(self):
        result = widget.configure({'bar': {'layout': {'right': [widget.WIDGET, 'other']}},
                                   'disabledPlugins': [widget.WIDGET, 'keep.disabled'],
                                   'plugins': [{'id': widget.WIDGET}, {'id': 'keep.plugin'}]})
        self.assertEqual(result['bar']['layout']['right'], ['other'])
        self.assertEqual(result['disabledPlugins'], ['keep.disabled'])
        self.assertEqual(result['plugins'], [{'id': 'keep.plugin'}])

    def test_symlink_widget_is_not_overwritten(self):
        plugins = self.home / 'omarchy/plugins'
        plugins.mkdir()
        (plugins / widget.WIDGET).symlink_to(self.source, target_is_directory=True)
        before = self.shell.read_text()
        with self.assertRaises(ValueError):
            widget.install(self.home, self.source)
        self.assertEqual(self.shell.read_text(), before)


if __name__ == '__main__':
    unittest.main()
