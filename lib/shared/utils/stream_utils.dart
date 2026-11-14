import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Event transformer that cancels the in-flight handler whenever a new event
/// of the same type arrives (switchMap semantics).
///
/// Use it for handlers that subscribe to long-lived streams via
/// `emit.forEach`, so that reloading (e.g. switching months) replaces the
/// previous subscription instead of stacking a new one on top of it.
EventTransformer<E> restartable<E>() {
  return _switchMap;
}

Stream<T> _switchMap<S, T>(Stream<S> source, Stream<T> Function(S) mapper) {
  late final StreamController<T> controller;
  StreamSubscription<S>? outer;
  StreamSubscription<T>? inner;
  var outerDone = false;

  controller = StreamController<T>(
    onListen: () {
      outer = source.listen(
        (event) {
          inner?.cancel();
          inner = mapper(event).listen(
            controller.add,
            onError: controller.addError,
            onDone: () {
              inner = null;
              if (outerDone) controller.close();
            },
          );
        },
        onError: controller.addError,
        onDone: () {
          outerDone = true;
          if (inner == null) controller.close();
        },
      );
    },
    onCancel: () async {
      await inner?.cancel();
      await outer?.cancel();
    },
  );

  return controller.stream;
}

/// Emits [combiner] of the latest value of each stream once all three have
/// emitted at least once, and again every time any of them emits.
Stream<R> combineLatest3<A, B, C, R>(
  Stream<A> streamA,
  Stream<B> streamB,
  Stream<C> streamC,
  R Function(A a, B b, C c) combiner,
) {
  late final StreamController<R> controller;
  final subscriptions = <StreamSubscription<Object?>>[];
  late A latestA;
  late B latestB;
  late C latestC;
  var hasA = false;
  var hasB = false;
  var hasC = false;
  var doneCount = 0;

  void emitIfReady() {
    if (hasA && hasB && hasC) {
      controller.add(combiner(latestA, latestB, latestC));
    }
  }

  void onDone() {
    doneCount += 1;
    if (doneCount == 3) controller.close();
  }

  controller = StreamController<R>(
    onListen: () {
      subscriptions
        ..add(
          streamA.listen(
            (value) {
              latestA = value;
              hasA = true;
              emitIfReady();
            },
            onError: controller.addError,
            onDone: onDone,
          ),
        )
        ..add(
          streamB.listen(
            (value) {
              latestB = value;
              hasB = true;
              emitIfReady();
            },
            onError: controller.addError,
            onDone: onDone,
          ),
        )
        ..add(
          streamC.listen(
            (value) {
              latestC = value;
              hasC = true;
              emitIfReady();
            },
            onError: controller.addError,
            onDone: onDone,
          ),
        );
    },
    onCancel: () => Future.wait(subscriptions.map((s) => s.cancel())),
  );

  return controller.stream;
}
