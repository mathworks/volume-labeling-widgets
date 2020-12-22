%% Load the axes in traditional figure
oldfig = openfig('figLayerBug2.fig');
ax = oldfig.Children;


%% Get the children
c = ax.Children;
hblue = c(1);   % Z = 50
hyel = c(2);    % Z = 53.5714
hred = c(3);    % Z = 53.5714
himg = c(4);    % Z = 53.5714


%% Move it to uifigure - Red goes missing!
uifig = uifigure;
ax.Parent = uifig;


%% Hide image  - Red still missing!
himg.Visible = 'off';


%% Hide blue line - Red reappears now!
hblue.Visible = 'off';
