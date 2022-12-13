# SnapshotTest

Take a snapshot of any view in your app, store the reference and test that the view looks the same throughout development.

## Install

Add the package to your Test-targets with SPM

## Example

```swift
class SnapshotViewTests: XCTestCase, SnapshotTestCase {
    func test() throws {
        try verifySnapshot {
            SnapshotView()
        }
    }
}
```

## Config

### Launch arguments

You can specify the following in your Test scheme Launch Arguments:

`-RecordingSnapshot` - If you want to have the test result be store directly in your reference folder

You can specify the following in your Test scheme Launch Environment:

`snapshotReferences` - The folder where the snapshot references are stored
`snapshotFailures` - The folder where the failing test result will end up
`snapshotTolerance` - A double which represents how much you allow the reference and result to diff

*TIP:* Use `$(SRCROOT)` to point the references and failures to a location in your project, don't forget to _Expand Variables Based On_ your app.

*TIP:* Add your `snapshotFailures` path to your `.gitignore` file.

### Function arguments
