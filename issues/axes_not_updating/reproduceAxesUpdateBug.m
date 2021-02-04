% Prepare a figure and layout
f = uifigure;
g = uigridlayout(f,[1 1]);

% Create the widget
obj = wt.VolumeViewer(g);

%%
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

% Find the axes handle
ax = obj.Axes;

% Axes parent (uipanel)
axpnl = ax.Parent;

% Panel parent (grid layout)
axgrid = axpnl.Parent;

%% Provide the volume data to the app
disp('set vol model');
obj.VolumeModel = volModel;


%% Tiledlayout bug

% f = uifigure;
% g = uigridlayout(f,[1 2]);
% g.ColumnWidth = {100 '1x'};
% s = uislider(g,'Orientation','vertical');
% s.Layout.Column = 1;
% g2 = uigridlayout(g,[1 1]);
% g2.Layout.Column = 2;
% g2.Padding = [0 0 0 0];
% t = tiledlayout(g2,1,1);
% a = axes(t);


%% Attempt 2