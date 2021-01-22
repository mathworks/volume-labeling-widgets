%% Load in data

s2 = load('mristack.mat');

% Place data into a VolumeModel
volModel = wt.model.VolumeModel;
volModel.ImageData = s2.mristack;

% Provide the world coordinates from edge to edge
volModel.WorldExtent = [
    0 300 % Y dimension in mm
    0 300 % X dimension in mm
    0 150 % Z dimension in mm
    ];


%% Create the app

app = wt.apps.VolumeAnnotationApp('VolumeModel',volModel);


%% Add Starting Annotations
% This is just for show, to make the screenshot of the app in action

app.AnnotationViewer.Slice = 21;

thisPoints = [
    173.7510   96.2490  146.4285
    169.3740  121.2510  146.4285
    197.4990  113.1240  146.4285
    ];

pointsAnnotation = wt.model.PointsAnnotation(...
    'Name','Points Annotation',...
    'Points',thisPoints,...
    'Color',[1 1 0]);
app.AnnotationViewer.addAnnotation(pointsAnnotation);


%% Add an interactive mask annotation

maskAnnotation = wt.model.MaskAnnotation.fromVolumeModel(...
    app.VolumeModel,...
    'Name','Mask Annotation',...
    'Color',[0 1 1],...
    'Alpha',0.5);
app.AnnotationViewer.addInteractiveAnnotation(maskAnnotation);

app.forceUpdate();


%% Get handles to low level graphics

fig = app.Figure;
ax = app.AnnotationViewer.Axes;
axParent = ax.Parent;

% The yellow markers
yellowMarker = pointsAnnotation.Plot;

% The red brush circle indicator
brushTool = app.AnnotationViewer.CurrentTool;
redCircleTransform = brushTool.BrushTransform;
redCircle = brushTool.BrushIndicator;

% Make the brush circle bigger
brushTool.BrushSize = 15;


%% Examples showing the bug
%% Toggle red brush circle visibility off
% This behaves as expected
redCircle.Visible = 0;

%% Toggle red brush circle visibility on
% This behaves as expected
redCircle.Visible = 1;

%% Toggle visibility off
% Unexpected!  This causes the red circle to disappear too!!!
yellowMarker.Visible = 0;

%% Toggle visibility on
% This causes the red circle to reappear!!!
yellowMarker.Visible = 1;


% ax.XLim = app.VolumeModel.WorldExtent(1,:);
% ax.YLim = app.VolumeModel.WorldExtent(2,:);
% ax.ZLim = app.VolumeModel.WorldExtent(3,:);
% redCircle.XLimInclude

%% Toggle include
redCircle.ZLimInclude = ~redCircle.ZLimInclude;

% redCircle.XLimInclude = 0;
% redCircle.YLimInclude = 0;
% redCircle.ZLimInclude = 0;