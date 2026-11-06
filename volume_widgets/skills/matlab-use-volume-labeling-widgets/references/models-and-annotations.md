# Work with imagery and annotations

Use this reference after establishing the app's development approach. Paths are
relative to the selected `volumeRoot` defined in the main skill.

## Preserve the coordinate contracts

| Value | Contract |
| --- | --- |
| `VolumeModel.ImageData` | Numeric 3D array indexed `(Y,X,Z)`; preserve intensity scale and type |
| `DataSize`, `PixelExtent`, `PixelEdges`, `PixelCenters` | Three dimensions in Y/X/Z order |
| `WorldExtent` | A 3-by-2 matrix with rows `[Ymin Ymax; Xmin Xmax; Zmin Zmax]`, measured at outer voxel edges |
| `WorldExtentPixelCenters` | Derived extents at first/last voxel centers; read-only in current source |
| Point-based annotation `Points` | N-by-3 world coordinates in `[Y X Z]` order |
| `IsosurfaceModel.Vertices` and graphics-axis points | N-by-3 `[X Y Z]` coordinates |
| `IsosurfaceModel.Faces` | N-by-3 vertex indices for triangles |
| `VolumeViewer.Slice3D`, `SlicePlaneViewer.Slice` | Slice indices in `[Y X Z]` order, not world positions |

Use positive integer slice indices. Viewer getters clamp them to the dataset;
validate user input at the application boundary rather than relying on that for
all invalid values. `VolumeViewer.Slice` addresses the dimension selected by
`View`: XY slices Z, XZ slices Y, and YZ slices X. `SliceDimension` identifies
that dimension. Use `getSliceIndex`, `getSliceRange`, and `getSliceXYZ` for the
model's coordinate mapping instead of recreating it.

Model grids assume uniform spacing in each dimension. Establish the origin,
spacing, orientation, and units before attaching masks or labels. If input
metadata cannot be represented by this grid, handle it explicitly in the
application's import/resampling layer. Do not silently treat arbitrary patient
orientations or nonuniform spacing as verified geometry.

The following synthetic dataset has unequal dimensions and spacing, which makes
axis-order mistakes visible:

```matlab
imageData = reshape(uint16(1:4800), 20, 30, 8);
volModel = wt.model.VolumeModel('ImageData', imageData);
volModel.WorldExtent = [0 40; 0 90; 0 32];
% Voxel spacing is [2;3;4] in Y/X/Z order.
% First voxel center is [1;1.5;2].
```

Assign `ImageData` and `WorldExtent`; the model calculates the read-only grid
properties. Do not copy the older Getting Started statement that both edge and
center extents can be assigned.

For DICOM folders, `wt.model.VolumeModel.fromDicomFile(folder)` uses
`dicomreadVolume` from Image Processing Toolbox. Current import code checks
spacing and can warn/adjust nonuniform Z coordinates. Preserve warnings and
verify the resulting world grid against the user's metadata. The protected
import method's `Crop` option is not a public `fromDicomFile` argument.

## Attach imagery to viewers

```matlab
fig = uifigure;
grid = uigridlayout(fig, [1 1]);
viewer = wt.VolumeQuadLabeler(grid);
viewer.VolumeModel = volModel;
viewer.View = 'xy';
viewer.Slice = 4;
```

`VolumeQuadLabeler` passes the same imagery model to `TopView`, `SideView`, and
`SliceView`. Its main `Slice3D` coordinates drive these views, and side/top
`ViewChanged` events update the corresponding coordinate. Use this public main
view state rather than wiring another synchronization loop.

Imagery models are handles and can be shared between displays intentionally.
Assigning a model attaches the widget's own change listener. App-owned listeners
that observe the model must be reattached when the app replaces it.

Default viewer constructors load bundled demonstration imagery. Assign the
application's model explicitly; successful construction alone does not prove
the requested dataset is displayed.

## Build meshes in the intended world coordinates

For the synthetic `volModel` above:

```matlab
threshold = median(double(volModel.ImageData(:)));
[faces, vertices] = isosurface(double(volModel.ImageData), threshold);
spacingXYZ = volModel.PixelExtent([2 1 3])';
originXYZ = [volModel.PixelCenters{2}(1), ...
    volModel.PixelCenters{1}(1), volModel.PixelCenters{3}(1)];
vertices = originXYZ + (vertices - 1) .* spacingXYZ;
isoModel = wt.model.IsosurfaceModel('Faces', faces, 'Vertices', vertices);
```

`isosurface` without coordinate grids returns voxel-index XYZ vertices. The
conversion above uses the centers and spacing of a uniformly spaced volume.
For real data, choose the threshold from the application's intensity units and
handle an empty mesh. For an existing world-coordinate mesh, retain its coordinate
system instead of applying this transform again.

Assign `isoModel` to an isosurface viewer's `IsosurfaceModel`. The viewer accepts
a row array for multiple meshes. Leave `VertexNormals` empty to let graphics
calculate them from the mesh, or compute normals consistently with the transformed
geometry. Do not calculate voxel-space normals using already scaled vertices.

## Create and manage annotation models

Points, lines, polygons, and planes are `wt.model.PointsAnnotation`,
`LineAnnotation`, `PolygonAnnotation`, and `PlaneAnnotation`. Planes are mainly
useful with isosurfaces; current `MaxPoint` permits 3 or 4 defining points. Masks
are logical voxel arrays for volumes and are not an isosurface annotation type.

With the volume `viewer` above:

```matlab
pointYXZ = [volModel.PixelCenters{1}(10), ...
    volModel.PixelCenters{2}(15), volModel.PixelCenters{3}(4)];
points = wt.model.PointsAnnotation('Name', 'Landmark', ...
    'Points', pointYXZ, 'Color', [1 0 0]);
viewer.addAnnotation(points);
viewer.selectAnnotation(points);

mask = wt.model.MaskAnnotation.fromVolumeModel(volModel, ...
    'Name', 'Region', 'Mask', volModel.ImageData > 2400, ...
    'Color', [0 0.6 1], 'Alpha', 0.5);
viewer.addAnnotation(mask);
```

`MaskAnnotation.fromVolumeModel` starts with a logical mask matching the imagery
size and copies its `WorldExtent`. An override still needs to match both. The
mask does not automatically follow later imagery-grid changes.

Use `addAnnotation` for configured annotations and `addInteractiveAnnotation`
for a new annotation the user will draw. Use `launchEditingTool(annotation)` to
resume editing a supported annotation and `launchSelectTool` to select by mouse.
`finishAnnotation` stops editing and retains the annotation; `cancelAnnotation`
removes pending edited annotations. Cancellation is not an undo of edits made to
an existing annotation. `removeAnnotation` detaches it from the viewer without
necessarily destroying an object retained by the application.

Selection and visibility are model state (`IsSelected`, `IsVisible`). Read
`SelectedAnnotationModel`, `PendingAnnotationModel`, and
`IsAddingInteractiveAnnotation` to drive controls. Guard empty selections and
disable actions that require a scalar annotation. Use a heterogeneous row array
of `wt.model.BaseAnnotationModel` for the collection, including its empty state.

For masks, configure brush properties only while the brush is active:

```matlab
viewer.addInteractiveAnnotation(mask);
tool = viewer.CurrentTool;
if isscalar(tool) && isa(tool, 'wt.tool.Brush')
    tool.BrushSize = 5;
    tool.Erase = false;
end
viewer.finishAnnotation();
```

Brush size is in voxels; use positive integers and the example's odd-diameter
convention. `mask.invert()` inverts the entire mask; passing a cell index selection
inverts that region. Left mouse input paints/adds points, right mouse input
erases/deletes points, and a double-click finishes. Zoom/pan/rotate toolbar modes
suspend annotation clicks until those modes are turned off.

Annotation models also own their graphics and slice-filter state. Sharing one
object across independent labelers can reuse the wrong plot parent or overwrite
its filter. For independent labelers, create separate annotation instances from
the common application data and synchronize the data deliberately. Do not assume
`copy` gives independent graphics; verify any chosen copying strategy.

## Observe changes and retain labels

Observe `PropertyChanged` on imagery/annotation models for data changes. Labelers
also expose `AnnotationModelChanged` (collection replacement),
`AnnotationChanged` (member properties), and `AnnotationStarted`,
`AnnotationStopped`, and `AnnotationSelected` (tool interactions). These
annotation events are ordinary events: use `event.listener`, not invented
`AnnotationChangedFcn` properties. Tool events use `wt.event.ToolInteractionData`;
inspect its `Model`, `Tool`, `Interaction`, and `CurrentPoint` contracts.

Retain app-owned listener handles, replace them when the model changes, and
release them on close. Render controls from the current model and tool state.
Avoid unconditional writes during refresh that cause a callback loop.

The example apps save the annotation collection as MAT variable `aObj`. Finish
editing first, then use the app's existing persistence boundary:

```matlab
aObj = viewer.AnnotationModel;
filePath = [tempname, '.mat'];
save(filePath, 'aObj');
saved = load(filePath, 'aObj');
```

Use a user-selected path in a real app, and temporary fixture paths in tests.
Loaded objects require their class definitions. Validate the variable's class,
mask alignment, and coordinate association before replacing current annotations.
Store the necessary imagery identity and units according to the application's
format; the example's MAT file alone does not establish that labels fit a different
volume. The example apps clear labels when replacing imagery. Match the user's
intended preserve/clear/migrate behavior instead of copying that policy silently.

Evidence: `+wt/+model`, `+wt/+mixin/AnnotationViewer.m`,
`+wt/VolumeQuadLabeler.m`, `+wt/+tool`, `doc/GettingStarted.mlx`, and
`examples/apps`. Repository-only tests: `TestVolumeModel`, `TestVolumeLabeler`,
`TestVolumeQuadLabeler`, and both labeling-app test classes under
`test/+wt/+test/+volume`.

<!-- Copyright 2026 The MathWorks, Inc. -->
