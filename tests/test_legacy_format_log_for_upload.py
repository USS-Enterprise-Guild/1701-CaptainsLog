#!/usr/bin/env python3

import importlib.util
import pathlib
import unittest


MODULE_PATH = pathlib.Path(__file__).resolve().parents[1] / "legacy" / "format_log_for_upload.py"


def load_module():
    spec = importlib.util.spec_from_file_location("legacy_format_log_for_upload", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


class LegacyFormatLogTests(unittest.TestCase):
    def test_get_player_name_across_day_boundary(self):
        module = load_module()
        player_entries = [
            ("3/9 23:59:59.999", "alpha"),
            ("3/10 00:00:00.000", "bravo"),
        ]

        player_name = module.get_player_name_for_timestamp("3/10 00:00:01.000", player_entries)

        self.assertEqual("bravo", player_name)


if __name__ == "__main__":
    unittest.main()
