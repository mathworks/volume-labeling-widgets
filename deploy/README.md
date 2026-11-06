# Release packaging

Build releases in MATLAB R2026a with `Volumelabelingwidgets.prj` open.
The project contains the native **Volume Labeling Widgets Toolbox** task.
Open it from **Project > Package Toolbox** or **Compiler Task Manager**.
Update its version and output filename, run **Reanalyze**, and select
**Package Toolbox**.

The 2.2.3 output is `release/Volume Labeling Widgets 2.2.3.mltbx`.
The toolbox keeps identifier `7beb8fae-7511-4c1a-a6fb-c1a109d46c80` and
declares compatibility with MATLAB R2022a and later. Image Processing
Toolbox and Widgets Toolbox 2.5.0 or later are required. Widgets Toolbox
is a separate add-on rather than bundled source.

The package contains `volume_widgets` source, examples, documentation,
icons, and component resources. Tests, deployment tooling, previous
release artifacts, and project/source-control metadata are not shipped.

MATLAB Project APIs manage the native task configuration and its file
labels. Do not manually edit the generated files under `resources/project`.
The legacy deployment `.prj` used machine-specific paths and has been
replaced by this project task.

Before retaining a release, run the test suite, inspect the package metadata
and file manifest, and smoke-test extracted contents with source-resolution
checks. Register the retained artifact and supporting files in the MATLAB
Project.

## Use the installed add-on while packaging

The development project references the Git submodule, whose startup script
disables the installed Widgets Toolbox add-on. For packaging only:

1. Close widget apps, then temporarily remove the `dependencies/widgets-toolbox`
   MATLAB Project reference from the References list. Keep the Git submodule.
2. Enable the installed Widgets Toolbox 2.5.0 add-on in Add-On Manager.
3. Check `which wt.abstract.BaseWidget -all`. It must resolve from the installed
   add-on rather than the submodule.
4. Reanalyze **Volume Labeling Widgets Toolbox**. Keep Widgets Toolbox as a
   required add-on with identifier `78895307-cc36-4970-8b66-0697da8f9352`,
   earliest version `2.5.0`, latest version `latest`, and `Exclude=false`.
   Leave its download URL empty for the MATLAB add-on repository association.
5. Package into `release`, then restore the development project reference and
   the add-on's previous enabled state. The current CI dependency setup stays
   unchanged.

The R2026a programmatic packaging API records the compatible MATLAB release
range and required add-ons, but does not write MATLAB product requirements.
Image Processing Toolbox remains an explicit prerequisite.

Copyright 2026 The MathWorks, Inc.
