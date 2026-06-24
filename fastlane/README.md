## fastlane documentation

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build app và upload lên TestFlight

### ios beta_with_notes

```sh
[bundle exec] fastlane ios beta_with_notes
```

Build + Upload TestFlight với changelog tùy chỉnh

### ios add_devices

```sh
[bundle exec] fastlane ios add_devices
```

Đăng ký UDID thiết bị test mới

---

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
