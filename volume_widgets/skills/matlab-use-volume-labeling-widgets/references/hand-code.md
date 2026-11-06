# Integrate with hand-coded apps

Use this reference when existing application code or the user's explicit choice
establishes hand code. Toolbox paths are relative to `volumeRoot`.

## Compose into the existing app first

Create viewers under the existing `uifigure` layout and retain widget, model, and
listener handles in the app's established state. Use `uigridlayout` and
`Layout.Row` / `Layout.Column` for resizing. An isosurface viewer needs an
`IsosurfaceModel`; volume viewers need a `VolumeModel`.

A full hand-coded app need not inherit from a toolbox app base. Keep an existing
class, nested-function, or model/view architecture when composition meets the
task. Do not introduce another framework merely to host the viewer.

For an already established hand-code task, this standalone integration recipe
uses the synthetic `volModel` from [Models and annotations](models-and-annotations.md):

```matlab
fig = uifigure;
grid = uigridlayout(fig, [1 2]);
grid.ColumnWidth = {'1x', 260};
viewer = wt.VolumeQuadLabeler(grid);
viewer.Layout.Column = 1;
viewer.VolumeModel = volModel;
list = wt.AnnotationLabelsList(grid);
list.Layout.Column = 2;
list.AnnotationModel = viewer.AnnotationModel;
collectionListener = event.listener(viewer, 'AnnotationModelChanged', ...
    @(src,evt)set(list, 'AnnotationModel', src.AnnotationModel));
```

Retain `collectionListener` in the real app's state. The list observes property
changes within its current collection, but the app must update that collection
when annotations are added or removed. Bind its `SelectionChangedFcn` to the
application's selection method; `evt.Value` contains row indices. The example
above intentionally covers collection synchronization only.

Separate loading, label persistence, and domain operations from rendering.
Model handle identity can be shared intentionally, while annotations' plot/filter
ownership requires the rules in the models reference. Avoid refreshing the UI by
recreating all widgets or replacing the quad labeler's synchronization.

## Reuse app infrastructure when it is needed

The shipped `examples/apps/+handCode` namespace contains:

- `BaseLabelingApp`, which derives from `wt.apps.BaseApp` and supplies common
  controls, annotation-list binding, and label import/export callbacks.
- `VolumeLabelingApp`, which adds `wt.VolumeQuadLabeler`, brush controls, and
  app-level mouse-wheel slice navigation.
- `IsosurfaceLabelingApp`, which hosts `wt.IsosurfaceLabeler` and mesh loading.

Use these to understand the pattern or copy/adapt required pieces into the user's
namespace. Consumer apps should not depend permanently on `handCode`. The base
example assigns `app` into the base workspace for debugging; do not carry that
side effect into a production app by default.

If choosing `wt.apps.BaseApp`, its constructor creates `Figure` and root `Grid`.
Implement protected `setup` to create controls and `update` to refresh them; do
not create a second figure or grid. Preferences load before setup, and remaining
property/value inputs are applied afterward. Use the selected dependency's exact
lifecycle instead of assuming every constructor input is available during setup.
The volume example creates its `AnnotationViewer` before calling the common
labeling setup, which attaches listeners to that viewer.

Use `matlab-use-widgets-toolbox` when available for `BaseSingleSessionApp`,
`BaseMultiSessionApp`, preferences, aggregation, and reusable model/view bases.
Read the selected class and its templates if that skill is unavailable. Session
management is an optional app capability, not required for displaying a volume.
Keep persistence data separate from UI handles and listeners.

## Preserve interaction and lifecycle behavior

The widgets provide slice controls; mouse-wheel navigation across quad views is
implemented by the volume example app, not promised by every standalone viewer.
If the user wants it, adapt the example's figure listener and hit-region logic.
Use the selected view's slice limits and `ZoomActive` state; do not overwrite
other figure callbacks or allow scrolling outside the viewer to change its slice.

App control refresh should follow collection/selection/model changes and tool
start/stop events so buttons stay correct after mouse interactions and finishing.
Use public viewer methods for editing. Do not assign read-only `CurrentTool` or
drive hidden child buttons as a production API.

Before closing the app, finish/stop active tools while their figure is valid,
release app-owned listeners and tasks, then destroy owned UI resources. Define
whether models survive the window; deleting the figure is not a label-save policy.
Keep user-facing save/cancel behavior in the application's normal close flow.

Resolve copied icons through `widgetsRoot` (the dependency's `icons` folder) or
the user's own asset directory. The examples' icon basenames rely on runtime
paths; copying an example file alone does not copy its assets. Use
[Validation and delivery](validation-and-delivery.md) for app checks and cleanup.

Evidence: `examples/apps/+handCode` and Widgets Toolbox
`+wt/+apps/BaseApp.m`. Repository-only tests parameterize both development
approaches in `TestVolumeLabelingApps` and `TestIsosurfaceLabelingApps`.

<!-- Copyright 2026 The MathWorks, Inc. -->
