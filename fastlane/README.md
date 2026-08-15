fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build_simulator

```sh
[bundle exec] fastlane ios build_simulator
```

Build the app for the simulator — the fast, no-signing check

### ios test

```sh
[bundle exec] fastlane ios test
```

Run the WalletKit test target — no simulator/app boot required

### ios ci

```sh
[bundle exec] fastlane ios ci
```

What CI actually runs on every push: test, then build

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
