/// [Level]s to control logging output. Logging can be enabled to include all
/// levels above certain [Level].
enum Level {
  debug(2000),//todo rename to trace?
  info(3000),
  warning(4000),
  error(5000);

  final int value;

  const Level(this.value);
}
