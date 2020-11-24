classdef (Hidden) VolumeModel <  uiw.model.BaseModel & uiw.mixin.HasDataGridXYZ
    % VolumeModel - data model for a volume of imagery data
    %
    % Syntax:
    %       obj = VolumeModel
    %       obj = VolumeModel('Property','Value',...)
    %
    % Notes:
    %
    %
    
    % Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting $Author: rjackey $ $Revision: 336 $  $Date: 2019-05-17 16:21:36 -0400 (Fri, 17 May 2019) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (AbortSet, SetObservable)
        Name (1,:) char %Name of this volume
        ImageData (:,:,:) {mustBeNumeric} = zeros([0,0,0],'uint16') % Volume imagery
        Alpha (1,1) double {mustBeFinite, mustBeNonnegative, mustBeLessThanOrEqual(Alpha,1)} = 1 % Alpha setting
    end %properties
    
    properties (AbortSet)
        Tag (1,:) char %Tag identifier of this volume
        UserData %UserData of this volume
    end
    
    properties (Dependent=true, SetAccess=protected)
        DataSize
    end %properties (dependent)
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function onDataGridChanged(obj)
            % Computes the DataRange and VoxelSize
            
            % Call superclass method
            obj.onDataGridChanged@uiw.mixin.HasDataGridXYZ();
            
            % Notify listeners of changes
            evt = uiw.event.EventData(...
                'EventType','DataChanged',...
                'Model',obj);
            obj.notify('ModelChanged',evt)
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        function set.ImageData(obj,value)
            obj.ImageData = value;
            obj.onDataGridChanged(); %DataChanged event
        end
        
        function value = get.DataSize(obj)
            value = size(obj.ImageData);
            if numel(value)==2
                value(3) = size(obj.ImageData,3);
            end
        end
        
    end %methods
    
end % classdef