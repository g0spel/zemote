import 'package:flutter_test/flutter_test.dart';

import 'package:zemote/ui/task_home_page.dart';

void main() {
  group('applyWorkspaceListUpdate (global workspace-list event)', () {
    test('never introduces taskIds unknown to the scoped list', () {
      final merged = applyWorkspaceListUpdate(
        [
          {'taskId': 'mine', 'title': '旧标题', 'updatedAt': 1},
        ],
        [
          {'taskId': 'other-ws-task', 'title': '别的区', 'updatedAt': 9},
        ],
        {},
        (_) => false,
      );
      expect(merged, hasLength(1));
      expect(merged.first['taskId'], 'mine');
    });

    test('updates known tasks and keeps their fields', () {
      final merged = applyWorkspaceListUpdate(
        [
          {
            'taskId': 'a',
            'title': '旧',
            'pinned': true,
            'updatedAt': 1,
          },
        ],
        [
          {'taskId': 'a', 'title': '新', 'updatedAt': 5},
        ],
        {},
        (_) => false,
      );
      expect(merged, hasLength(1));
      expect(merged.first['title'], '新');
      expect(merged.first['pinned'], isTrue);
      expect(merged.first['updatedAt'], 5);
    });

    test('archived flag removes the task and records the id', () {
      final archived = <String>{};
      final merged = applyWorkspaceListUpdate(
        [
          {'taskId': 'a', 'updatedAt': 1},
          {'taskId': 'b', 'updatedAt': 1},
        ],
        [
          {'taskId': 'a', 'archived': true},
        ],
        archived,
        (_) => false,
      );
      expect(merged.map((t) => t['taskId']), ['b']);
      expect(archived, {'a'});
    });

    test('hidden (recently removed) tasks stay filtered out', () {
      final merged = applyWorkspaceListUpdate(
        [
          {'taskId': 'a', 'updatedAt': 2},
          {'taskId': 'gone', 'updatedAt': 2},
        ],
        [
          {'taskId': 'a', 'updatedAt': 3},
        ],
        {},
        (id) => id == 'gone',
      );
      expect(merged.map((t) => t['taskId']), ['a']);
    });
  });
}
