import tempfile
import unittest
from pathlib import Path
from server import Store


def operation(index, deleted=False):
    return {'opId': ('delete:' if deleted else 'upsert:') + str(index),
            'operation': 'delete' if deleted else 'upsert',
            'record': {'id': str(index), 'signCode': 'A', 'label': 'A',
                       'confirmedAt': 100, 'deletedAt': 200 if deleted else None}}


class StoreTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.store = Store(str(Path(self.directory.name) / 'fixture.sqlite'))

    def tearDown(self):
        self.directory.cleanup()

    def test_pagination_and_restart(self):
        for index in range(105):
            self.store.push(operation(index))
        page = self.store.pull(0)
        self.assertEqual(len(page['records']), 100)
        self.assertTrue(page['hasMore'])
        reopened = Store(self.store.path)
        last = reopened.pull(int(page['cursor']))
        self.assertEqual(len(last['records']), 5)
        self.assertFalse(last['hasMore'])

    def test_delete_before_upsert_and_idempotency(self):
        self.store.push(operation(1, deleted=True))
        self.store.push(operation(1))
        self.store.push(operation(1))
        self.assertEqual(len(self.store.pull(0)['records']), 1)
        self.assertEqual(self.store.pull(0)['records'][0]['deletedAt'], 200)

    def test_reused_id_with_changed_payload_is_rejected(self):
        self.store.push(operation(1))
        changed = operation(1)
        changed['record']['label'] = 'B'
        with self.assertRaises(ValueError):
            self.store.push(changed)
        self.assertEqual(self.store.pull(0)['records'][0]['label'], 'A')

    def test_rejects_images_and_invalid_timestamps(self):
        for key, value in [('photo', 'private'), ('confirmedAt', -1)]:
            invalid = operation(1)
            invalid['record'][key] = value
            with self.assertRaises(ValueError):
                self.store.push(invalid)


if __name__ == '__main__':
    unittest.main()
