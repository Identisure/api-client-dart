class PollOptions {
  const PollOptions({
    this.interval = const Duration(seconds: 2),
    this.timeout = const Duration(minutes: 5),
  });

  final Duration interval;
  final Duration timeout;
}
