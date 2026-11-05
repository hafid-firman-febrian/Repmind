import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:repmind/core/errors/app_exception.dart';
import 'package:repmind/features/coach/data/data_sources/coach_sse_parser.dart';
import 'package:repmind/features/coach/domain/models/coach_stream_event.dart';

Stream<List<int>> chunks(List<String> parts) =>
    Stream.fromIterable(parts.map(utf8.encode));

void main() {
  test('parses started, delta and done', () async {
    final events = await parseCoachStream(
      chunks([
        'data: {"type":"started","user_message_id":"u-1"}\n\n',
        'data: {"type":"delta","text":"Hello"}\n\n',
        'data: {"type":"done","message_id":"m-1","proposal":{"based_on_plan_id":"plan-1","day_number":2,"summary":"Swap","changes":[{"from_exercise_id":"a","to_exercise_id":"b","to_exercise_name":"B","sets":3,"reps":"12","rest_seconds":60}]},"user_confirmed":true}\n\n',
      ]),
    ).toList();

    expect((events[0] as CoachStarted).userMessageId, 'u-1');
    expect((events[1] as CoachDelta).text, 'Hello');
    final done = events[2] as CoachDone;
    expect(done.messageId, 'm-1');
    expect(done.userConfirmed, isTrue);
    expect(done.proposal!.basedOnPlanId, 'plan-1');
    expect(done.proposal!.changes.single.toExerciseId, 'b');
  });

  test('done without a proposal carries null', () async {
    final events = await parseCoachStream(
      chunks([
        'data: {"type":"done","message_id":"m-1","proposal":null,"user_confirmed":false}\n\n',
      ]),
    ).toList();

    final done = events.single as CoachDone;
    expect(done.proposal, isNull);
    expect(done.userConfirmed, isFalse);
  });

  test('joins a character split across chunks', () async {
    final bytes = utf8.encode('data: {"type":"delta","text":"Bahu 💪"}\n\n');
    final events = await parseCoachStream(
      Stream.fromIterable([
        bytes.sublist(0, bytes.length - 8),
        bytes.sublist(bytes.length - 8),
        ...[
          utf8.encode(
            'data: {"type":"done","message_id":"m","proposal":null,"user_confirmed":false}\n\n',
          ),
        ],
      ]),
    ).toList();

    expect((events.first as CoachDelta).text, 'Bahu 💪');
  });

  test('an event split across chunks arrives once', () async {
    final events = await parseCoachStream(
      chunks([
        'data: {"type":"del',
        'ta","text":"Hi"}\n',
        '\ndata: {"type":"done","message_id":"m","proposal":null,',
        '"user_confirmed":false}\n\n',
      ]),
    ).toList();

    expect(events, hasLength(2));
    expect((events[0] as CoachDelta).text, 'Hi');
    expect(events[1], isA<CoachDone>());
  });

  test('ignores an unknown event type', () async {
    final events = await parseCoachStream(
      chunks([
        'data: {"type":"ping"}\n\n',
        'data: {"type":"done","message_id":"m","proposal":null,"user_confirmed":false}\n\n',
      ]),
    ).toList();

    expect(events.single, isA<CoachDone>());
  });

  test('an error event throws CoachReplyFailure', () async {
    final stream = parseCoachStream(
      chunks([
        'data: {"type":"delta","text":"Partial"}\n\n',
        'data: {"type":"error","code":"ai_unavailable"}\n\n',
      ]),
    );

    final received = <CoachStreamEvent>[];
    await expectLater(
      stream.forEach(received.add),
      throwsA(isA<CoachReplyFailure>()),
    );
    expect(received.single, isA<CoachDelta>());
  });

  test('a stream that ends without done throws CoachReplyFailure', () async {
    final stream = parseCoachStream(
      chunks(['data: {"type":"delta","text":"Cut off"}\n\n']),
    );

    await expectLater(stream.toList(), throwsA(isA<CoachReplyFailure>()));
  });
}
