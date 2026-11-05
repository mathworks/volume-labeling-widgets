# Release packaging

Build releases in MATLAB R2026a with `Volumelabelingwidgets.prj` open.
The project contains the native **Volume Labeling Widgets** toolbox task.
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

Copyright 2026 The MathWorks, Inc.
