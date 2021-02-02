% Prepare a figure and layout
f = uifigure;
g = uigridlayout(f,[1 1]);

% Create the widget
obj = wt.VolumeViewer(g);

% Import sample data
s2 = load('mristack.mat');

% Place data into a VolumeModel
volModel = wt.model.VolumeModel;
volModel.Name = 'mristack';
volModel.ImageData = s2.mristack;

% Provide the world coordinates from edge to edge
volModel.WorldExtent = [
    0 300 % Y dimension in mm
    0 300 % X dimension in mm
    0 150 % Z dimension in mm
    ];

% Provide the volume data to the app
obj.VolumeModel = volModel;

% Find the axes handle
ax = obj.Axes;

% Axes parent (uipanel)
axpnl = ax.Parent;

% Panel parent (grid layout)
axgrid = axpnl.Parent;