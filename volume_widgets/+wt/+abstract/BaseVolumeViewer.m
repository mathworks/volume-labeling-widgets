classdef (Abstract, Hidden) BaseVolumeViewer < wt.abstract.BaseAxesViewer
    % Base class for Volume visualization showing one or more slice planes on axes
    
    % Copyright 2018-2021 The MathWorks, Inc.
    
    
    %% Properties
    properties (AbortSet)
        
        % Data model for the volume's data
        VolumeModel (1,1) wt.model.VolumeModel = wt.model.VolumeModel
        
    end %properties
    
    
    %% Internal Properties
    properties (Transient, Access = private, UsedInUpdate = false)
        
        % Listener to VolumeModel changes
        VolumeModelChangedListener event.listener 
        
    end %properties
    
 
    
    %% Setup
    methods (Access = protected)
        function setup(obj)
            
            % Load default volume model for demonstration
            obj.loadDefaultVolumeModel();
            
            % Call superclass setup first
            obj.setup@wt.abstract.BaseAxesViewer();      
            
            % Set initial listener
            obj.onModelSet();
            
        end %function
    end %methods
    
    
    
    %% Protected Methods
    methods (Access = protected)
        
        
        function onModelSet(obj)
            % Configure VolumeModel listener
            
            % Listen to changes in VolumeModel
            obj.VolumeModelChangedListener = event.listener(obj.VolumeModel,...
                'PropertyChanged',@(h,e)onModelChanged(obj,e) );
            
        end %function
        
        
        function img = createImagePlot(obj)
            % Creates a default surface plot for displaying imagery
            
            img = matlab.graphics.primitive.Surface(...
                    'Parent',obj.Axes,...
                    'XData',[],...
                    'YData',[],...
                    'ZData',[],...
                    'CData',[],...
                    'CDataMapping','scaled',...
                    'FaceColor','texturemap',...
                    'FaceAlpha',1,...
                    'HitTest','off',...
                    'EdgeColor','none');
            
        end %function
        
        
        function loadDefaultVolumeModel(obj)
            % Populates the default volume model for demonstration
            
            % Load default volume data
            persistent volumeData
            if isempty(volumeData)
                s = load("mristack.mat");
                volumeData = flip(s.mristack, 3);
                volumeData(:,:,16:end) = [];
            end
            
            % Create a default volume model
            volModel = wt.model.VolumeModel;
            volModel.ImageData = volumeData;
            volModel.WorldExtent = [
                0 300 % Y dimension in mm
                0 300 % X dimension in mm
                0 150 % Z dimension in mm
                ];
            
            % Store the result
            obj.VolumeModel = volModel;
            
        end %function
        
    end %methods
        
    
    
    
    %% Get/Set Methods
    methods
        
        function set.VolumeModel(obj,value)
            
            % Update the value
            obj.VolumeModel = value;
            
            % Update listener, etc.
            obj.onModelSet();
            
            % Workaround for g228243 (fixed in R2021a)
            if verLessThan('matlab','9.10')
                obj.requestUpdate();
            end %if
            
        end %function
        
    end %methods
    
end % classdef