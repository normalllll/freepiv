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
}) async {
  write(optimistic);

  try {
    await mutate();
    write(settle(read()));
  } catch (_) {
    write(rollback(previous));
    rethrow;
  }
}
