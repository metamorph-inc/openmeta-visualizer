[![Build status](https://ci.appveyor.com/api/projects/status/spief0ppp2yh5y3g?svg=true)](https://ci.appveyor.com/project/Metamorph/openmeta-visualizer)

# OpenMETA Visualizer

## Development:

To build: run `python Dig\tab-src\surrogate-modeling\build.py`

Then, add registry entry to note location of this repository: `add_reg_path.cmd`

## Testing

1. Install Microsoft Visual Studio.

1. Open DigTest/DigTest.sln in Visual Studio.

1. Run Debug > Start Debugging.

## Release Process:

To create a new release of the Visualizer:

1. First make sure your changes pass all tests by running them locally using the `DigTest/DigTest.sln` project or pushing the changes without a tag and letting AppVeyor build them. If you are running the tests locally, you will need to set your screen resolution to 1024x768 for the tests to run properly.

NOTE: Put testing instructions here.

1. Update the version and release date information in the "About" section of the Visualizer. This can be done by modifying the code at the bottom of the `Dig/app.R` file. Commit this change.

1. Create an annotate tag with the new version number, add a meaningful tag message, and push the tag.

   ```bash
   git tag -a vX.Y.Z
   git push origin vX.Y.Z
   ```
