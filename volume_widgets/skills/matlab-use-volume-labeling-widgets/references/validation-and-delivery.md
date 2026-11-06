# Verify and deliver the consumer app

Use the application's existing test conventions. Toolbox repository tests are
evidence and examples when a checkout is available; consumer tests must not
require `wt.test.volume` or assume it ships with the installed add-on.

## Verify observable behavior

Use `matlab.unittest.TestCase` for model/services and `matlab.uitest.TestCase` for
supported UI gestures. Apply only the scenarios relevant to the user's change:

| Area | Checks |
| --- | --- |
| Imagery | Correct model and rendered data; dtype/intensity preserved; empty data handled by the app |
| Coordinates | Unequal dimensions and voxel spacing; edge/center conversion; correct XY/XZ/YZ slice mapping |
| Quad views | New imagery reaches all auxiliary viewers; main/side/top slice changes stay coordinated |
| Annotations | Add/select/edit/finish/remove; empty selection; names/colors/visibility update controls |
| Masks | Size and world extent match imagery; brush/erase affects the displayed slice in each supported view |
| Interaction modes | Zoom/pan/rotate suppress annotation clicks; editing resumes after modes are turned off |
| Rebinding | Replacing imagery/list collections updates listeners; stale models do not drive the app |
| Persistence | Temporary-file round trip, invalid variable/class, mismatched imagery, cancel preserves current labels |
| Lifecycle | Close during editing stops tools and releases listeners; no leftover figures or tasks |
| App Designer | Runtime construction plus saved-app editor reload and registered custom components |

Use synthetic unequal-sized arrays or bundled data for deterministic tests.
The simple array in the models reference is 20-by-30-by-8 with Y/X/Z spacing
2/3/4. Assertions against equal sizes or isotropic spacing can miss axis swaps.
Avoid interactive downloads or OS file dialogs in automated tests; test the
application's load/save boundary separately from native dialog selection.

ComponentContainer rendering is deferred. Prefer constraints to arbitrary waits:

```matlab
% Inside a test method with viewer bound to volModel:
import matlab.unittest.constraints.Eventually
import matlab.unittest.constraints.IsEqualTo
viewer.View = 'xy';
viewer.Slice = 4;
testCase.verifyThat(@()viewer.SliceView.Slice, ...
    Eventually(IsEqualTo(viewer.Slice3D), 'WithTimeoutOf', 5));
```

Programmatic assignment verifies synchronization, not mouse callbacks. Use a
supported UI gesture to test user interaction and assert its effect on model
data or rendered output. A nonempty graphics handle alone does not prove the
intended image or annotation appeared. Test displayed data or representative
rendered detail when rendering is part of the requirement.

## Clean up what the test owns

Register fixture teardown for figures, temporary files, app-owned listeners,
models, preferences, and tasks. Stop editing before deleting the figure. Preserve
user workspaces, open figures, preferences, and add-on enabled states. Example
apps may assign a debug `app` variable and persist preferences; their repository
test base demonstrates restoring those states.

Do not use `close all`, `clear classes`, or `restoredefaultpath` as consumer test
setup/cleanup. Those affect unrelated apps and can disrupt MCP. Ordinary
`forceUpdate` calls are debugging aids, not a production refresh contract.

Run the narrowest relevant suite through MATLAB MCP in the actual target release.
Expand testing when a failure or new concern warrants it. Report failures and
incomplete results separately; verify rendered interactions in a UI-capable
session. If the environment cannot run a check, identify it as unverified.

## Verify App Designer through its load path

When the app uses registered custom components, check the selected classes and
registration metadata, instantiate the widgets, and reload the saved app in the
target release. A JSON parser and a runtime constructor cannot certify the
Registration Framework or editor load.

Record ordinary MATLAB object-loading warnings as well as App Designer
compatibility warnings. A successful load status alone is not a warning-free
result; verify that the application's intended model and data are displayed.

Use `matlab-appdesigner-compatibility` when available for diagnostic validation;
otherwise follow the target release's supported App Designer workflow and report
the editor outcome. Diagnostic internal calls do not belong in consumer runtime
code. Preserve the app's selected format, including its `.xml` companion for an
R2026b+ plain-text App Designer app.

## Deliver with explicit dependencies

Confirm `wt.VolumeViewer` and `wt.abstract.BaseWidget` resolve from the intended
toolboxes and that required data/assets are present. Check both toolboxes' versions
and product requirements; a successful package install alone does not prove a
working dependency path. When copying example behavior, replace relative data
and icon assumptions with installation-relative or application-relative paths.

For a compiled app, include its own model/view classes, both toolbox dependencies,
and required assets. Editing tools are constructed by class name through
`str2func`; include `wt.tool.Select`, `wt.tool.Vertices`, and `wt.tool.Brush` when
their behavior is used, plus custom tool classes. Similarly, explicitly include
any application classes launched by name. Verify the deployed app rather than
assuming dynamic dependencies are discovered automatically.

MATLAB Compiler, parallel computing products, Web App Server, and MATLAB Online
are not prerequisites for ordinary desktop consumption. When the user requests
one of those targets, validate its specific file access, dialogs, graphics, and
execution requirements. Do not claim support based only on desktop tests.

Deliver the app entry point, selected release/toolbox versions, dependency setup,
and exact checks/results. Keep toolbox example namespaces and maintainer release
scripts out of the consumer's runtime dependencies.

## Maintainer checks for this skill

This section applies to retaining the skill in the toolbox repository, not to
developing a consumer app. Register every permanent skill/reference file with
`Volumelabelingwidgets.prj` through supported MATLAB Project APIs and verify actual
membership. Inspect the native toolbox task's inclusion configuration to ensure
the `volume_widgets/skills` contents are retained. The folder does not need a
MATLAB path entry. Do not rebuild, version, or publish a release merely to check
skill inclusion.

Repository-only evidence: `test/+wt/+test/+volume/TestVolumeModel.m`,
`TestVolumeViewer.m`, `TestVolumeLabeler.m`, `TestVolumeQuadLabeler.m`,
`LabelingAppTestBase.m`, `TestVolumeLabelingApps.m`, `TestIsosurfaceLabelingApps.m`,
and `TestToolbarModes.m`. The established runner is `runVolumeTestSuite`, which
runs the complete `wt.test.volume` suite; consumer projects use their own runner.

<!-- Copyright 2026 The MathWorks, Inc. -->
