typedef StateReader<T> = T Function();
typedef StateWriter<T> = void Function(T value);

Future<void> runOptimisticMutation<T>({
  required T previous,
  required T optimistic,
  required StateReader<T> read,
  required StateWriter<T> write,
  required Future<void> Function() mutate,
  required T Function(T current) settle,
  required T Function(T previous) rollback,
  bool Function()? canCommit,
}) async {
  bool active() => canCommit?.call() ?? true;
  if (!active()) return;
  write(optimistic);

  try {
    await mutate();
    if (active()) write(settle(read()));
  } catch (_) {
    if (active()) write(rollback(previous));
    rethrow;
  }
}
