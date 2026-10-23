# Contributing

By submitting a contribution, you confirm your right to license it under
[the package license](LICENSE.txt).

External contributions are welcome. Use a Conventional Commit PR title and
follow `.swift-format`. Maintainers follow the shared
[signing instructions](https://github.com/swift-library/.github/blob/master/MAINTENANCE.md#signing).

Run these checks before opening a pull request:

```sh
swift build
swift test
swift build -c release
swift build --package-path Examples/PDFViewer --force-resolved-versions
xcrun swift-format lint --strict --configuration .swift-format --recursive \
  Package.swift Sources Tests Examples/PDFViewer/Package.swift Examples/PDFViewer/Sources
```

[`.github/swift-package.json`](.github/swift-package.json) declares the compiler
matrix, formatting paths, iOS tests, visionOS build, DocC target and the
PDFViewer example build for CI.
Required checks are `policy / policy` and `validate / result`.

Review the [release facts and mechanics](Documentation/Reference/Release.md)
and the [swift-library versioning standard](https://github.com/swift-library/.github/blob/master/VERSIONING.md)
when changing compatibility, requirements or release inputs.
