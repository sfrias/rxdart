import 'dart:async';

import 'package:test/test.dart';
import 'package:rxdart/rxdart.dart';

Stream<int> _getStream() {
  return new Stream<int>.fromIterable(<int>[1, 2, 3]);
}

Stream<num> _getOtherStream(num value) {
  StreamController<num> controller = new StreamController<num>();

  new Timer(
      // Reverses the order of 1, 2, 3 to 3, 2, 1 by delaying 1, and 2 longer
      // than they delay 3
      new Duration(milliseconds: value == 1 ? 15 : value == 2 ? 10 : 5), () {
    controller.add(value);
    controller.close();
  });

  return controller.stream;
}

void main() {
  test('rx.Observable.flatMap', () async {
    const List<int> expectedOutput = const <int>[3, 2, 1];
    int count = 0;

    new Observable<int>(_getStream())
        .flatMap(_getOtherStream)
        .listen(expectAsync1((num result) {
          expect(result, expectedOutput[count++]);
        }, count: expectedOutput.length));
  });

  test('rx.Observable.flatMap.asBroadcastStream', () async {
    Stream<num> stream = new Observable<int>(_getStream().asBroadcastStream())
        .flatMap(_getOtherStream);

    // listen twice on same stream
    stream.listen((_) {});
    stream.listen((_) {});
    // code should reach here
    expect(true, true);
  });

  test('rx.Observable.flatMap.error.shouldThrow', () async {
    Stream<num> observableWithError =
        new Observable<num>(new ErrorStream<num>(new Exception()))
            .flatMap(_getOtherStream);

    observableWithError.listen(null, onError: (dynamic e, dynamic s) {
      expect(e, isException);
    });
  });

  test('rx.Observable.flatMap.pause.resume', () async {
    StreamSubscription<int> subscription;
    Observable<int> stream =
        new Observable<int>.just(0).flatMap((_) => new Observable<int>.just(1));

    subscription = stream.listen(expectAsync1((int value) {
      expect(value, 1);

      subscription.cancel();
    }, count: 1));

    subscription.pause();
    subscription.resume();
  });
}
