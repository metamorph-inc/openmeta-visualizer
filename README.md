[![Build status](https://ci.appveyor.com/api/projects/status/spief0ppp2yh5y3g?svg=true)](https://ci.appveyor.com/project/Metamorph/openmeta-visualizer)

# OpenMETA Visualizer

## Development:

To build: run `python Dig\tab-src\surrogate-modeling\build.py`

Then, add registry entry to note location of this repository: `add_reg_path.cmd`

## Release Process:

To create a new release of the Visualizer, first make sure your changes pass all tests by running them locally using the `DigTest/DigTest.sln` project or pushing the changes without a tag and letting AppVeyor build them.

When you have confirmed all tests are passing, simply create an annotate tag with the new version number, add a meaningful tag message, and push the tag.

```bash
git tag -a vX.Y.Z
git push origin vX.Y.Z
```
