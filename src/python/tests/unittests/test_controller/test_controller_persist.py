# Copyright 2017, Inderpreet Singh, All rights reserved.

import unittest
import json

from common import PersistError
from controller import ControllerPersist


class TestControllerPersist(unittest.TestCase):
    def test_from_str(self):
        content = """
        {
            "downloaded": ["one", "two", "th ree", "fo.ur"],
            "extracted": ["fi\\"ve", "si@x", "se\\\\ven", "ei-ght"]
        }
        """
        persist = ControllerPersist.from_str(content)
        golden_downloaded = {"one", "two", "th ree", "fo.ur"}
        golden_extracted = {"fi\"ve", "si@x", "se\\ven", "ei-ght"}
        self.assertEqual(golden_downloaded, persist.downloaded_file_names)
        self.assertEqual(golden_extracted, persist.extracted_file_names)

    def test_to_str(self):
        persist = ControllerPersist()
        persist.downloaded_file_names.add("one")
        persist.downloaded_file_names.add("two")
        persist.downloaded_file_names.add("th ree")
        persist.downloaded_file_names.add("fo.ur")
        persist.extracted_file_names.add("fi\"ve")
        persist.extracted_file_names.add("si@x")
        persist.extracted_file_names.add("se\\ven")
        persist.extracted_file_names.add("ei-ght")
        dct = json.loads(persist.to_str())
        self.assertTrue("downloaded" in dct)
        self.assertEqual({"one", "two", "th ree", "fo.ur"}, set(dct["downloaded"]))
        self.assertTrue("extracted" in dct)
        self.assertEqual({"fi\"ve", "si@x", "se\\ven", "ei-ght"}, set(dct["extracted"]))

    def test_to_and_from_str(self):
        persist = ControllerPersist()
        persist.downloaded_file_names.add("one")
        persist.downloaded_file_names.add("two")
        persist.downloaded_file_names.add("th ree")
        persist.downloaded_file_names.add("fo.ur")
        persist.extracted_file_names.add("fi\"ve")
        persist.extracted_file_names.add("si@x")
        persist.extracted_file_names.add("se\\ven")
        persist.extracted_file_names.add("ei-ght")

        persist_actual = ControllerPersist.from_str(persist.to_str())
        self.assertEqual(
            persist.downloaded_file_names,
            persist_actual.downloaded_file_names
        )
        self.assertEqual(
            persist.extracted_file_names,
            persist_actual.extracted_file_names
        )

    def test_persist_read_error(self):
        # bad pattern
        content = """
        {
            "downloaded": [bad string],
            "extracted": []
        }
        """
        with self.assertRaises(PersistError):
            ControllerPersist.from_str(content)
        content = """
        {
            "downloaded": [],
            "extracted": [bad string]
        }
        """
        with self.assertRaises(PersistError):
            ControllerPersist.from_str(content)

        # empty json
        content = ""
        with self.assertRaises(PersistError):
            ControllerPersist.from_str(content)

        # missing keys
        content = """
        {
            "downloaded": []
        }
        """
        with self.assertRaises(PersistError):
            ControllerPersist.from_str(content)
        content = """
        {
            "extracted": []
        }
        """
        with self.assertRaises(PersistError):
            ControllerPersist.from_str(content)

        # malformed
        content = "{"
        with self.assertRaises(PersistError):
            ControllerPersist.from_str(content)

    def test_max_tracked_files_default(self):
        """Test that default max_tracked_files is used."""
        persist = ControllerPersist()
        self.assertEqual(
            ControllerPersist.DEFAULT_MAX_TRACKED_FILES,
            persist.max_tracked_files
        )

    def test_max_tracked_files_custom(self):
        """Test custom max_tracked_files value."""
        persist = ControllerPersist(max_tracked_files=100)
        self.assertEqual(100, persist.max_tracked_files)

    def test_eviction_on_add(self):
        """Test that oldest items are evicted when limit is reached."""
        persist = ControllerPersist(max_tracked_files=3)
        persist.downloaded_file_names.add("file1")
        persist.downloaded_file_names.add("file2")
        persist.downloaded_file_names.add("file3")
        persist.downloaded_file_names.add("file4")  # file1 should be evicted

        self.assertNotIn("file1", persist.downloaded_file_names)
        self.assertIn("file2", persist.downloaded_file_names)
        self.assertIn("file3", persist.downloaded_file_names)
        self.assertIn("file4", persist.downloaded_file_names)

    def test_eviction_stats(self):
        """Test that eviction stats are tracked."""
        persist = ControllerPersist(max_tracked_files=2)
        persist.downloaded_file_names.add("file1")
        persist.downloaded_file_names.add("file2")
        persist.downloaded_file_names.add("file3")  # file1 evicted
        persist.extracted_file_names.add("ext1")
        persist.extracted_file_names.add("ext2")
        persist.extracted_file_names.add("ext3")  # ext1 evicted

        stats = persist.get_eviction_stats()
        self.assertEqual(1, stats['downloaded_evictions'])
        self.assertEqual(1, stats['extracted_evictions'])
        self.assertEqual(2, stats['max_tracked_files'])

    def test_from_str_with_max_tracked_files(self):
        """Test from_str respects max_tracked_files and evicts oldest."""
        content = """
        {
            "downloaded": ["file1", "file2", "file3", "file4", "file5"],
            "extracted": []
        }
        """
        persist = ControllerPersist.from_str(content, max_tracked_files=3)

        # Only last 3 files should be kept
        self.assertEqual(3, len(persist.downloaded_file_names))
        self.assertNotIn("file1", persist.downloaded_file_names)
        self.assertNotIn("file2", persist.downloaded_file_names)
        self.assertIn("file3", persist.downloaded_file_names)
        self.assertIn("file4", persist.downloaded_file_names)
        self.assertIn("file5", persist.downloaded_file_names)

    def test_serialization_preserves_order(self):
        """Test that serialization preserves insertion order."""
        persist = ControllerPersist(max_tracked_files=10)
        persist.downloaded_file_names.add("third")
        persist.downloaded_file_names.add("first")
        persist.downloaded_file_names.add("second")

        dct = json.loads(persist.to_str())
        # Order should be preserved
        self.assertEqual(["third", "first", "second"], dct["downloaded"])

    def test_difference_update(self):
        """Test that difference_update works correctly."""
        persist = ControllerPersist(max_tracked_files=10)
        persist.downloaded_file_names.add("file1")
        persist.downloaded_file_names.add("file2")
        persist.downloaded_file_names.add("file3")

        persist.downloaded_file_names.difference_update({"file2", "nonexistent"})

        self.assertIn("file1", persist.downloaded_file_names)
        self.assertNotIn("file2", persist.downloaded_file_names)
        self.assertIn("file3", persist.downloaded_file_names)
