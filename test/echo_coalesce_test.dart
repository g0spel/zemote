import 'package:flutter_test/flutter_test.dart';

import 'package:zemote/protocol/conversation.dart';
import 'package:zemote/ui/chat_page.dart';

void _injectSnapshot(ConversationState state, {int seq = 1}) {
  state.applyFrame({
    'payload': {
      'kind': 'snapshot',
      'snapshot': {
        'control': {'phase': 'completed'},
        'rows': {
          'window': [
            {'rowId': 1, 'kind': 'user', 'text': 'hi'},
          ],
          'totalCount': 1,
          'firstRowId': 1,
        },
      },
    },
    'toSeq': seq,
  }, onGap: () => fail('snapshot gap'));
}

void main() {
  group('removeEchoedTexts (optimistic echo dedupe)', () {
    test('echo removed once the real userInput row arrives', () {
      final echoes = [
        {'text': '你好', 'ts': 1},
        {'text': '在吗', 'ts': 2},
      ];
      final rows = [
        {'kind': 'assistantText', 'text': 'hi', 'rowId': 1},
        {'kind': 'userInput', 'text': '你好', 'rowId': 2},
      ];
      final kept = removeEchoedTexts(echoes, rows);
      expect(kept, hasLength(1));
      expect(kept.first['text'], '在吗');
    });

    test('whitespace-insensitive match', () {
      final echoes = [
        {'text': ' 你好 ', 'ts': 1},
      ];
      final rows = [
        {'kind': 'userInput', 'text': '你好', 'rowId': 2},
      ];
      expect(removeEchoedTexts(echoes, rows), isEmpty);
    });

    test('non-userInput rows never match', () {
      final echoes = [
        {'text': '你好', 'ts': 1},
      ];
      final rows = [
        {'kind': 'assistantText', 'text': '你好', 'rowId': 1},
      ];
      expect(removeEchoedTexts(echoes, rows), hasLength(1));
    });
  });

  group('ConversationState notify coalescing', () {
    test('burst of frames produces one notification per window', () async {
      final state = ConversationState();
      addTearDown(state.dispose);
      var notified = 0;
      state.addListener(() => notified++);

      _injectSnapshot(state, seq: 1);
      for (var i = 0; i < 5; i++) {
        state.applyFrame({
          'payload': {
            'kind': 'deltas',
            'deltas': [
              {
                'op': 'row.appended',
                'row': {'rowId': i + 10, 'kind': 'assistantText', 'text': 'chunk $i'},
              },
            ],
          },
          'fromSeq': 1 + i,
          'toSeq': 2 + i,
        }, onGap: () => fail('no gap'));
      }

      // Rows are applied synchronously; listeners fire on the flush timer.
      expect(state.rows, hasLength(6)); // snapshot row + 5 deltas
      expect(notified, 0);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(notified, 1);
    });
  });
}
