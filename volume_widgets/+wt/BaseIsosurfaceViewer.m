classdef (Hidden) BaseIsosurfaceViewer < wt.BaseAxesViewer
    % Base class for Isosurface visualization on axes
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    
    %% Properties
    properties (AbortSet)
        
        % Data model for the isosurface's data
        IsosurfaceModel (1,:) wt.model.IsosurfaceModel
        
    end %properties
    
    
    %% Internal Properties
    properties (Transient, Hidden, SetAccess = protected)
        
        % Lighting
        Light matlab.graphics.primitive.Light
        
    end %properties
    
    
    properties (Transient, Access = private, UsedInUpdate = false)
        
        % Listener to IsosurfaceModel changes
        IsosurfaceModelChangedListener event.listener
        
    end %properties
    
    
    %% Setup
    methods (Access = protected)
        function setup(obj)
            
            % Call superclass setup first
            obj.setup@wt.BaseAxesViewer();
            
            % Add lighting to upper front right
            lightColor = [.8 .7 .7];
            obj.Light(1) = light(...
                'Parent',obj.Axes,...
                'Style','infinite',...
                'Color',lightColor,...
                'Position',[1 -1 1]);
            
            % Add lighting to upper front left
            lightColor = [.8 .7 .7];
            obj.Light(end+1) = light(...
                'Parent',obj.Axes,...
                'Style','infinite',...
                'Color',lightColor,...
                'Position',[-1 -1 1]);
            
            % Add lighting to lower rear left
            lightColor = [.7 .4 .1];
            obj.Light(end+1) = light(...
                'Parent',obj.Axes,...
                'Style','infinite',...
                'Color',lightColor,...
                'Position',[-1 1 -1]);
            
            % Add lighting to lower rear right
            lightColor = [.7 .4 .1];
            obj.Light(end+1) = light(...
                'Parent',obj.Axes,...
                'Style','infinite',...
                'Color',lightColor,...
                'Position',[1 1 -1]);
            
            % Set initial listener
            obj.onModelSet();
            
        end %function
    end %methods
    
    
    
    %% Update
    methods (Access = protected)
        function update(~,~)
            
            %RAJ - Avoid marking abstract due to g219447
            
        end %function
    end %methods
    
    
    
    %% Callbacks
    methods (Access = protected)
        
        function onModelChanged(obj,evt)
            
            % Subclass may override this and choose to redraw based on the
            % event, if necessary for more complex scenarios.
            obj.update(evt);
            
        end %function
        
        
        function onModelSet(obj)
            
            % Listen to changes in IsosurfaceModel
            obj.IsosurfaceModelChangedListener = event.listener(obj.IsosurfaceModel,...
                'PropertyChanged',@(h,e)onModelChanged(obj,e) );
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        function set.IsosurfaceModel(obj,value)
            obj.IsosurfaceModel = value;
            obj.onModelSet();
        end %function
        
    end %methods
    
end % classdef