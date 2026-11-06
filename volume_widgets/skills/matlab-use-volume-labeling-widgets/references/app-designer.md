# Integrate with App Designer

Use this reference when existing code or the user's explicit choice establishes
App Designer. Toolbox paths are relative to `volumeRoot`.

## Preserve the host app and its format

Inspect the existing app, its editable callbacks/properties, and layout containers.
Keep generated `matlab.apps.AppBase` structure. Do not insert `wt.apps.BaseApp`
into its superclass list or replace generated component creation code with a
hand-coded example app.

Both `.mlapp` and R2026b+ App Designer `.m`/`.xml` pairs are App Designer apps.
For new apps, resolve the format choice through the user's preferences and target
release. When available, use `matlab-build-app` and its format-specific authoring
guidance. Otherwise use the release's App Designer workflow. Preserve both files
of a plain-text app and its generated/editable ownership boundaries. Do not
rewrite a binary archive to author it or convert formats merely to add a widget.

## Use registered components or create them during startup

`resources/appDesigner.json` registers the seven components listed in the main
skill in the **Volume Labeling Widgets** Component Library category. Use a
registered component in Design View when that suits the app. Assign its imagery
model and app-owned listeners in startup; keep the model and application services
outside generated UI creation code.

Alternatively, create a widget in an existing app container during `startupFcn`
and retain it in an app property. This preserves App Designer as the development
approach, although the runtime-created widget is not part of the design canvas.

For an app with an existing `ViewerGrid` grid and declared
`AnnotationViewer wt.VolumeQuadLabeler` and `VolumeModel wt.model.VolumeModel`
properties, the startup body can contain:

```matlab
app.AnnotationViewer = wt.VolumeQuadLabeler(app.ViewerGrid);
app.AnnotationViewer.Layout.Row = 1;
app.AnnotationViewer.Layout.Column = 1;
app.AnnotationViewer.VolumeModel = app.VolumeModel;
```

Initialize `app.VolumeModel` before assigning it, or use the model-loading
method already established by the app. Use the existing parent layout's row and
column conventions. A registered viewer already on the canvas needs the model
assignment, not a second viewer creation. Do not access child axes as a substitute
for the model API or replace the viewer's axes/container.

## Bind controls to model and tool state

Declare app properties to retain `event.listener` handles. Listen to the viewer's
`AnnotationModelChanged`, `AnnotationSelected`, `AnnotationChanged`,
`AnnotationStarted`, and `AnnotationStopped` as needed by the app's controls.
Plain annotation events have no automatically generated `...Fcn` property.

Refresh the annotation list from `app.AnnotationViewer.AnnotationModel` and drive
the edit/finish/delete/brush controls from the current selection and active tool.
`wt.AnnotationLabelsList.SelectionChangedFcn` receives a
`wt.eventdata.ValueChangedData` whose `Value` is selected row indices; it is not
an annotation object. Resolve valid indices against the current collection and
handle empty or multiple selections according to the app's selection behavior.
Rename and visibility edits change the annotation models directly.

`VolumeViewer.ViewChangedFcn` is available for view/slice interaction. Use the
model/listener path for data changes rather than assuming a programmatic property
assignment invokes a user callback. Keep loading, persistence, and domain logic
in focused app methods or services.

Use these shipped examples as references, not as required runtime dependencies:

| Task | Example |
| --- | --- |
| Volume/quad labeling, brush controls, slice scrolling | `examples/apps/VolumeLabelingExample.mlapp` |
| Isosurface labeling, points/lines/polygons/planes | `examples/apps/IsosurfaceLabelingExample.mlapp` |

The examples forward public model properties to the viewer and attach listeners
in startup. Adapt the necessary behavior into the user's app. Omit demonstration
workspace assignments, fixed thresholds, and unrelated controls unless requested.

## Validate runtime and editor loading separately

Confirm the intended class installation, instantiate the component, assign the
application model, and test a representative interaction in the target release.
Also reload the saved app through App Designer and verify its custom components
are available without missing/errored-component warnings. Runtime construction
and successful JSON parsing alone do not establish editor compatibility.

For registration/load problems, use `matlab-appdesigner-compatibility` when
available. Inspect version/path conflicts and the selected metadata first. Keep
diagnostic internal APIs out of consumer runtime code and do not modify the
installed toolbox's registration metadata for an application-specific extension.
Use [Validation and delivery](validation-and-delivery.md) for teardown and tests.

Evidence: `resources/appDesigner.json`, both `.mlapp` examples, and
`examples/demoVolumeLabelingApp.mlx` / `demoIsosurfaceLabelingApp.mlx`.
Repository-only interaction evidence is in `LabelingAppTestBase`,
`TestVolumeLabelingApps`, and `TestIsosurfaceLabelingApps`.

<!-- Copyright 2026 The MathWorks, Inc. -->
