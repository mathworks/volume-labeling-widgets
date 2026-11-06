---
name: matlab-use-volume-labeling-widgets
description: Build or extend MATLAB applications with Volume Labeling Widgets Toolbox slice viewers, isosurface viewers, labelers, imagery models, and annotation tools. Use when integrating this toolbox into a custom app or modifying an app that uses its components. Requires existing application code that establishes the development approach, or an explicit App Designer versus hand-code choice, before app planning or implementation.
---

# Develop apps with Volume Labeling Widgets

Use the toolbox as a dependency of the user's application. Reuse its viewers,
imagery models, annotations, and editing tools before recreating their behavior.
Keep application-specific classes in the user's namespace, outside `+wt`.

## Establish the development approach first

Before recommending an app architecture, planning the app, or writing application
code, require one of these:

- **Existing application code:** Inspect the target app and establish whether it
  uses App Designer or hand code. Preserve that approach unless the user requests
  a change. A standalone widget demo or unrelated MATLAB script does not establish
  the approach for a new app.
- **An explicit choice:** Accept a choice already stated by the user. Otherwise
  explain the comparison below, ask **"Do you want to use App Designer or hand
  code?"**, and wait for the answer before dependent planning or implementation.

An App Designer `.mlapp` and an R2026b+ App Designer `.m`/`.xml` pair use the same
development approach. Inspect the structure and companion files before calling
an `.m` app hand-coded. If the existing app mixes approaches or the target is
ambiguous, ask which approach governs this work. Do not choose from app complexity,
appearance, or expected lifetime. Read-only discovery can continue while waiting;
do not repeat the question after the approach is established.

| Approach | Advantages | Tradeoffs |
| --- | --- | --- |
| **App Designer** | Visual layout editing, integrated property/callback tools, and registered toolbox components. Reusable models and services can live outside the generated app. | Preserve the generated top-level app structure. Widgets Toolbox `wt.apps` superclasses are intended for hand-coded apps. |
| **Hand code** | Flexible class and namespace organization, reusable views and services, and optional Widgets Toolbox app/session infrastructure. | Layout changes require editing code and running the app to inspect the result. |

Both approaches support modular logic and automated testing. App Designer versus
hand code is a development choice; `.mlapp` versus App Designer plain text is a
separate format choice. Preserve existing formats and the user's stated choices.

## Locate dependencies and confirm compatibility

Inspect the consumer project and its normal dependency setup. Prefer MATLAB MCP
when available; verify the session's release and the intended application project
before project-sensitive execution.

```matlab
version('-release')
which('wt.VolumeViewer', '-all')
which('wt.abstract.BaseWidget', '-all')
```

Confirm both toolboxes resolve from the intended installations before using them.
Volume Labeling Widgets and Widgets Toolbox share the `wt` namespace but are
separate dependencies. Missing classes and multiple installations require resolving
the dependency setup, not editing the user's app around a guessed API. Do not
disable add-ons automatically or assume an installer acquired every dependency.

After resolving the installation, locate its content without fixed machine paths:

```matlab
volumeRoot = fileparts(fileparts(which('wt.VolumeViewer')));
widgetsRoot = wt.utility.widgetsRoot();
```

All toolbox source, documentation, and example paths below and in the references
are relative to `volumeRoot`, unless marked otherwise. Skill-local links are
relative to this skill folder. These conventions still work when the whole skill
folder is copied into an agent's skill directory.

The current packaged toolbox declares MATLAB R2022a+ and Widgets Toolbox 2.5.0+
requirements, with Image Processing Toolbox required. This guidance was validated
using R2026b; confirm the selected versions and the consumer's release baseline.
Older prose lists different minimum releases. Newer App Designer formats, UI
gestures, theme APIs, and optional background execution have their own requirements.

For a source dependency, configure `volume_widgets` and `volume_widgets/data`
through the consumer project's path setup, alongside Widgets Toolbox's runtime
folders. Add `volume_widgets/examples/apps` only when running example apps. Do not
add `+wt` itself or recursively add all folders. Installed add-ons configure runtime
paths; the skill folder does not need a MATLAB path entry.

Do not open `Volumelabelingwidgets.prj` or `WidgetsToolbox.prj` merely to consume
the toolboxes. Their maintainer startup scripts close figures, clear classes, and
disable installed copies. Open the user's application project when its workflow
requires that project.

## Choose components and read focused guidance

| Application need | Component |
| --- | --- |
| Display one XY, XZ, or YZ slice | `wt.VolumeViewer` |
| Show three slice planes for spatial orientation | `wt.SlicePlaneViewer` |
| Add annotations to the current volume slice view | `wt.VolumeLabeler` |
| Label in a main slice view with coordinated side/top and 3D slice-plane views | `wt.VolumeQuadLabeler` |
| Display one or more triangular meshes | `wt.IsosurfaceViewer` |
| Annotate a 3D isosurface | `wt.IsosurfaceLabeler` |
| Show annotation names, colors, visibility, and selection | `wt.AnnotationLabelsList` |

Volume viewers display slices; they are not volumetric ray-casting renderers.
The quad labeler edits annotations in its main view; its auxiliary viewers provide
orientation. Use its existing synchronization rather than adding a second one.

| Task | Read when relevant |
| --- | --- |
| Load imagery, map coordinates, create/edit annotations, or save labels | [Models and annotations](references/models-and-annotations.md) |
| Integrate components into an App Designer app | [App Designer integration](references/app-designer.md) |
| Compose a hand-coded app or reuse optional app infrastructure | [Hand-coded integration](references/hand-code.md) |
| Verify interactions, editor loading, cleanup, or deployment | [Validation and delivery](references/validation-and-delivery.md) |

Start with `doc/GettingStarted.mlx`, the matching `examples/demo*.mlx`, and its
published `examples/html/demo*.html` when available. Inspect the resolved class
and relevant tests for exact properties, methods, and event payloads. Tests under
`test/+wt/+test/+volume` are repository-only evidence, not consumer dependencies.

The real quad component is `wt.VolumeQuadLabeler`; older prose also says
`VolumeLabelerQuadView`. Follow current source rather than copying that name.
Open examples by full path instead of changing folders or downloading sample data.
Use bundled or user-authorized data for development.

## Cooperate with other skills when available

This skill supplies the volume/isosurface integration contracts and is
self-contained. Other skills are optional and should not repeat the established
development-choice question or change the user's approach.

- Use `matlab-use-widgets-toolbox` for general controls, app/session bases,
  preferences, model/view observation, and custom component extension patterns.
- Use `matlab-build-app` for host-app layout and App Designer authoring after the
  development approach above is clear. Preserve chosen Widgets Toolbox framework
  patterns; a duplicate MVVM or binding layer is not required.
- Use `matlab-build-chart` for additional charts and `matlab-apply-theme` for
  requested styling. The viewers own ordinary MATLAB axes inside their containers;
  do not replace those axes with `uiaxes` to follow a generic app recipe.
- Use `matlab-write-tests` / `matlab-run-tests` for focused testing,
  `matlab-review-code` for review, and `matlab-appdesigner-compatibility` for
  component-registration or editor-load problems.
- Use applicable data I/O or performance skills when those operations are part of
  the user's task. Do not add products just to follow an optional example.

<!-- Copyright 2026 The MathWorks, Inc. -->
