[![Build status](https://ci.appveyor.com/api/projects/status/spief0ppp2yh5y3g?svg=true)](https://ci.appveyor.com/project/Metamorph/openmeta-visualizer)

# OpenMETA Visualizer

## Table of Contents
- [Development](#development)
- [Build & Test (local)](#build--test-local)
- [Build & Test (remote)](#build--test-remote)
- [Create a New Release](#create-a-new-release)
- [Additional Resources](#additional-resources)

## Development

### Edit Code

- The two main R files are [`app.R`](/Dig/app.R) and [`main_server.R`](/Dig/main_server.R).

- Also, each Visualizer tab has its own separate R file - located in the [`Dig\tabs\`](/Dig/tabs/) directory.

- While you can use any text editor to modify source files, [RStudio](https://www.rstudio.com/) is the recommended development tool.

### Build & Test (local)

Build:

1. Run `python Dig\tab-src\surrogate-modeling\build.py`

1. Add a registry entry to note location of this repository: `add_reg_path.cmd`

Run tests:

1. Install Microsoft Visual Studio.

1. Open `DigTest/DigTest.sln` in Visual Studio.

1. Run Debug > Start Debugging.

### Build & Test (remote)

Alternatively, you can:

1. Push your local changes to the [openmeta-visualizer](https://github.com/metamorph-inc/openmeta-visualizer) GitHub repository.

1. Doing so will automatically trigger AppVeyor job, which will build the Visualizer, run the tests, and also create a Windows installer.

Note 1: Building and testing remotely via AppVeyor is generally much slower than building and testing locally.

Note 2: Be especially sure to create a new development branch. You can squash merge your final changes to master (`git merge --squash <devel-branch-name>`).

## Create a New Release

To create a new release of the Visualizer:

1. First make sure your changes pass all tests by running them locally using the `DigTest/DigTest.sln` project 
   or pushing the changes without a tag and letting AppVeyor build them.
   If you are running the tests locally, you will need to set your screen resolution to 1024x768 for the tests to run properly.

1. Update the version and release date information in the "About" section of the Visualizer. 
   This can be done by modifying the code at the bottom of the [`main_server.R`](/Dig/main_server.R) file. Commit and push this change.

1. Create an annotate tag with the new version number, add a meaningful tag message, and push the tag.

   ```bash
   git tag -a vX.Y.Z
   git push origin vX.Y.Z
   ```
 
 ## Additional Resources
 
 ### R
 - [The R Primer](https://www.rprimer.dk/)
 
 ### R Shiny
 - [Getting Started with Shiny](https://ourcodingclub.github.io/tutorials/shiny/)
 - [Beginner's Guide to Creating an R Shiny App](https://towardsdatascience.com/beginners-guide-to-creating-an-r-shiny-app-1664387d95b3)
 - [Mastering Shiny](https://mastering-shiny.org/index.html)
 
 ### D3
 - [D3.js](https://d3js.org/)
 - [A Visual Reference for D3](https://www.freecodecamp.org/news/a-visual-reference-for-d3/)
 