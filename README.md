# Rewind

[![Pub Version](https://img.shields.io/pub/v/rewind.svg)](https://pub.dev/packages/rewind)
[![Dart Package Docs](https://img.shields.io/badge/documentation-pub.dev-blue.svg)](https://pub.dev/documentation/rewind/latest/)
[![License: MIT](https://img.shields.io/badge/license-MIT-purple.svg)](https://opensource.org/licenses/MIT)
[![Build Status](https://github.com/mcmah309/rewind/actions/workflows/dart.yml/badge.svg)](https://github.com/mcmah309/rewind/actions)


`rewind` is a logging tool that enables you to record any data, with full customization of what is captured and the appearance of your logs at every logging level.

click [here](#example-ouput) for an example output.

## How To Use
```dart
// set log level
Log.level = Level.info;
// log info
Log.i(object);
// log info with additional message
Log.i(object, append: "Some more information.");
// log info overriding the string verion of the object
Log.i(object, override: "Use this instead.");
// log info with a stactrace related to the log object.
// Note: No need to ever do `StackTrace.current` since that is taken 
// care of if you include the `LogPointComponent()` in your config
Log.i(object, stackTrace: stackTrace);
```
Since nothing will ever be logged unless `Log.level` is set, `rewind` is safe to use packages.

## Levels
See [here](#logging-guidelines) for when to use each:
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
    // the number of frames to keep if a stack trace is present.
    framesToKeep: 10,
    // components to be a part of the log
    components: [
        // Includes the Object runtime type
        ObjectTypeComponent(),
        // Stringifies the Object
        StringifiedComponent(),
        // Includes any appended messages
        AppendLogComponent(),
        // Creates a unique id for the log you can reference in the ui and/or intercept
        IdComponent(),
        // Captures the time at which the log occurred
        TimeComponent(),
        // Captures the stack trace at the point log was called
        LogPointComponent(),
  ]);
```
You can create your own custom `components` by extends the `LogComponent` class.

#### Selecting The Output
By default the output goes to the console. But you can change it for example with:
```dart
Log.output = FileOutput(file: File("path/to/file"), overrideExisting: true, encoding: utf8);
```
##### Suported Outputs
- Console
- File
- Memory
- Stream
- Multiple (combines any of the above)


## Logging Guidelines
Ever wonder what level to log at? Follow the flow chart below.
![Logging Guidelines](/assets/logging_guideline.png)


## anyhow
`rewind` is aware of types from the [anyhow](https://pub.dev/packages/anyhow) package. Therefore, when setting `framesToKeep`, rewind will adjust the stack trace display accordingly.

## Example Ouput
#### Multiple Components
![Multiple Components](/assets/1710119359_grim.png)
#### Single Component
![Stringified Only Pretty](/assets/1710119342_grim%20(1).png)
#### Single Component Simple Print
![Stringified Only Simple](/assets/1710119342_grim.png)