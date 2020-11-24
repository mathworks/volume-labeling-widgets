classdef (Hidden) IsosurfaceViewer < uiw.abstract.WidgetContainer & uiw.mixin.HasCallback
    % IsosurfaceViewer -
    %
    %
    %
    % Syntax:
    %       obj = IsosurfaceViewer
    %       obj = IsosurfaceViewer('Property','Value',...)
    %
    % Notes:
    %
    %
    
    % Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: joyeetam $
    %   $Revision: 338 $  $Date: 2018-10-29 16:54:30 -0400 (Mon, 29 Oct 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (AbortSet)
        IsosurfaceModel (:,1) uiw.model.IsosurfaceModel % Data model for the isosurface's data
    end %properties
    
    properties (Transient, Access=private)
        IsosurfaceModelChangedListener event.listener % Listener to IsosurfaceModel changes
    end %properties
    
    
    %% Constructor / destructor
    methods
        
        function obj = IsosurfaceViewer(varargin)
            % Construct the control
            
            % Call superclass constructor
            obj = obj@uiw.abstract.WidgetContainer();
            
            % Change defaults
            obj.BackgroundColor = [.1 .1 .1];
            obj.ForegroundColor = [.7 .7 .7];
            
            % Create the graphics items
            obj.create();
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Set initial listener
            obj.attachModelListener();
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.onResized();
            obj.onEnableChanged();
            obj.redraw();
            obj.onStyleChanged();
            
        end %constructor
        
    end %methods
    
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function resetView(obj)
            % Reset to the default view
            
            obj.h.Axes.View = [-37.5 30];
            
        end %function
        
    end %methods
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function create(obj)
            
            obj.hLayout.MainContainer = uicontainer(...
                'Parent',obj.hBasePanel,...
                'Units','normalized',...
                'Position',[0 0 1 1]);
            
            obj.h.Axes = axes(...
                'Parent',obj.hLayout.MainContainer,...
                'DataAspectRatio',[1 1 0.28],...
                'ZDir', 'normal',...
                'Visible','off',...
                'PickableParts','all',...
                'Units','normalized',...
                'Position',[0 0 1 1],...
                'View',[-37.5 30]);
            axis(obj.h.Axes,'tight');
            
            % Specify axes interactions
            if ~verLessThan('matlab','9.5')
                %disableDefaultInteractivity(obj.h.Axes);
                obj.h.Axes.Interactions = rotateInteraction;
                axtoolbar(obj.h.Axes,{'export','rotate',...
                    'pan','zoomin','zoomout','restoreview'});
            end
            
            obj.h.IsoPatch = matlab.graphics.primitive.Patch.empty(0);
            
            % Add lighting to upper front
            lightColor1 = [.9 .9 .7];
            obj.h.Light(1) = light(...
                'Parent',obj.h.Axes,...
                'Style','infinite',...
                'Color',lightColor1,...
                'Position',[1 0 1]);
            
            % Add lighting to lower rear
            lightColor2 = [0.8510 0.3294 0.1020];
            obj.h.Light(2) = light(...
                'Parent',obj.h.Axes,...
                'Style','infinite',...
                'Color',lightColor2,...
                'Position',[0 1 0]);
            
            % For debugging
            % disp('debug');
            % xlabel(obj.h.Axes,'X','Color',[1 1 1])
            % ylabel(obj.h.Axes,'Y','Color',[1 1 1])
            % zlabel(obj.h.Axes,'Z','Color',[1 1 1])
            % obj.h.Axes.Visible = 'on';
            
        end %function
        
        
        function redraw(obj)
            % Handle state changes that may need UI redraw
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                obj.redrawImagery();
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function redrawImagery(obj)
            % Handle state changes that may need UI redraw
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Loop on each isosurface, in case of multiple
                numIso = numel(obj.IsosurfaceModel);
                for idx = 1:numIso
                    
                    % Get the current isosurface model
                    isoModel = obj.IsosurfaceModel(idx);
                    
                    % Add another patch?
                    if numel(obj.h.IsoPatch) < idx || ~isvalid(obj.h.IsoPatch(idx))
                        obj.h.IsoPatch(idx) = matlab.graphics.primitive.Patch(...
                            'Parent',obj.h.Axes);
                        obj.h.IsoPatch(idx).DiffuseStrength = 0.8;
                        obj.h.IsoPatch(idx).SpecularStrength = 0.1;
                        obj.h.IsoPatch(idx).FaceColor = [.8 .8 .6];
                        obj.h.IsoPatch(idx).EdgeColor = 'none';
                    end
                    
                    % Set the data
                    obj.h.IsoPatch(idx).FaceAlpha = isoModel.Alpha;
                    obj.h.IsoPatch(idx).Faces = isoModel.Faces;
                    obj.h.IsoPatch(idx).Vertices = isoModel.Vertices;
                    
                    % Store the model that matches the patch
                    obj.h.IsoPatch(idx).UserData = isoModel;
                    
                    % Are vertex normals present?
                    if isempty(isoModel.VertexNormals)
                        obj.h.IsoPatch(idx).VertexNormalsMode = 'auto';
                    else
                        obj.h.IsoPatch(idx).VertexNormals = isoModel.VertexNormals;
                    end
                    
                end %for idx = 1:numIso
                
                % Remove any extra isosurfaces
                delete(obj.h.IsoPatch(numIso+1:end));
                obj.h.IsoPatch(numIso+1:end) = [];
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onModelSet(obj)
            
            % Redraw all
            obj.redraw();
            
        end %function
        
        
        function onModelChanged(obj,evt)
            
            % Subclass may override this and choose to redraw based on the
            % event, if necessary for more complex scenarios.
            
            switch evt.EventType
                
                case 'DataChanged'
                    obj.redrawImagery();
                    
                otherwise
                    % Do nothing
                    
            end %switch
            
        end %function
        
    end %methods
    
    
    
    %% Private Methods
    methods (Access=private)
        
        function attachModelListener(obj)
            
            % Listen to changes in IsosurfaceModel
            obj.IsosurfaceModelChangedListener = event.listener(obj.IsosurfaceModel,...
                'ModelChanged',@(h,e)onModelChanged(obj,e) );
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        function set.IsosurfaceModel(obj,value)
            obj.IsosurfaceModel = value;
            obj.attachModelListener();
            obj.onModelSet();
        end %function
        
    end %methods
    
end % classdef