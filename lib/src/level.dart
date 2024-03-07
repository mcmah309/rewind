/// [Level]s to control logging output. Logging can be enabled to include all
/// levels above certain [Level].
enum Level {
  /// Information useful for developers debugging the application, does not contain variable values.
  trace(1000),
  /// Information useful for developers debugging the application, contains variable values.
  debug(2000),
  /// Information useful for understanding the application flow. e.g. application lifecycle events.
  info(3000),
  /// Information about an unwanted state, but the process can continue to run. i.e. controlled flow.
  warning(4000),
  /// Information about an unwanted state, but the application will continue to run. control flow or state may be compromised.
  error(5000),
  /// Information about an unwanted state, the application will terminate after this log.
  fatal(6000);

  final int value;

  const Level(this.value);
}
