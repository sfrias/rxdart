import 'dart:async';

StreamTransformer<T, T> debounceTransformer<T>(Duration duration) {
  bool _closeAfterNextEvent = false;
  Timer _timer;

  return new StreamTransformer<T, T>((Stream<T> input, bool cancelOnError) {
    StreamController<T> controller;
    StreamSubscription<T> subscription;
    bool streamHasEvent = false;

    controller = new StreamController<T>(
        sync: true,
        onListen: () {
          subscription = input.listen(
              (T value) {
                streamHasEvent = true;

                if (_timer != null && _timer.isActive) _timer.cancel();

                _timer = new Timer(duration, () {
                  controller.add(value);

                  if (_closeAfterNextEvent) controller.close();
                });
              },
              onError: controller.addError,
              onDone: () {
                if (!streamHasEvent)
                  controller.close();
                else
                  _closeAfterNextEvent = true;
              },
              cancelOnError: cancelOnError);
        },
        onPause: ([Future<dynamic> resumeSignal]) =>
            subscription.pause(resumeSignal),
        onResume: () => subscription.resume(),
        onCancel: () => subscription.cancel());

    return controller.stream.listen(null);
  });
}
