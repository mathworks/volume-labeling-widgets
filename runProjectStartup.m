% Run project startup tasks

% Copyright 2019-2020 The MathWorks, Inc.


%% Close any open components first

close all
warning('off','MATLAB:ClassInstanceExists');
clear classes %#ok<CLCLS>
warning('on','MATLAB:ClassInstanceExists');


%% Disable any installed version

% Get installed addons
addonInfo = matlab.addons.installedAddons();

% Addon ID
addonId = "7beb8fae-7511-4c1a-a6fb-c1a109d46c80"; % Volume Labeling Widgets

% Disable
if ismember(addonId, addonInfo.Identifier)
    matlab.addons.disableAddon(addonId);
end