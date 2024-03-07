# Rewind

`rewind` is a logging utility that allows you completely customize what is captured and how your logs look at each logging level.

click [here]() for an example output.

## How To Use
```dart
// log info
Log.i(object)
// log warning with additional message
Log.w(object, append: "Some more information.")
// log error overriding the string verion of the object
Log.e(object, override: "Use this instead.")
```
## Levels
See [here]() for when to use each:
- `t`: trace
- `d`: debug
- `i`: info
- `w`: warning
- `e`: error
- `f`: fatal

## How To Configure
#### Log Level
```dart
Log.level = Level.trace;
```
#### Composing Log Level Configs
```dart
  // config for all not set
  Log.defaultLogConfig = LogLevelConfig.def(
    printer: SimplePrinter()
  );
  Log.warningLogConfig = LogLevelConfig.def(
    printer: PrettyPrinter()
  );
  Log.errorLogConfig = LogLevelConfig(
    printer: PrettyPrinter(),
    // the number of frames to keep if a stacktrace is present.
    framesToKeep: 10,
    // components to be a part of the log
    components: [
        ObjectTypeComponent(),
        StringifiedComponent(),
        AppendLogComponent(),
        IdComponent(),
        TimeComponent(),
        LogPointComponent(),
  ]);
```
You can create your own custom `components` by extends the `LogComponent` class.



## Logging Guidelines
Ever wonder what level to log at? Follow the flow chart below.
![Logging Guidelines](/assets/logging_guideline.png)


## anyhow
`rewind` is aware of types from the [anyhow]() package. Therefore, when setting `framesToKeep`, rewind will adjust the stack trace display accordingly.

## Example Ouput
config:
```dart

```
output: