classdef (Hidden) BaseVolumeViewer < wt.BaseAxesViewer
    % Base class for Volume visualization showing one or more slice planes on axes
    
    % This class should be abstract, however:
    % g2282435 UsedInUpdate fails for props in abstract classes

    % Copyright 2018-2020 The MathWorks, Inc.
    
    
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
            obj.setup@wt.BaseAxesViewer();       
            
            % Turn off clipping to best use axes space in 2D view
            obj.Axes.Clipping = 'off';
            
            % Set initial listener
            obj.onModelSet();
            
        end %function
    end %methods
    
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function onModelChanged(obj,~)
            
            % Subclass may override this and choose to redraw based on the
            % event, if necessary for more complex scenarios.
            obj.update();
            
        end %function
        
        
        function onModelSet(obj)
            
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
            obj.VolumeModel = value;
            obj.onModelSet();
        end %function
        
    end %methods
    
end % classdef