classdef (Hidden) AnnotationViewer < uiw.mixin.HasContainer & ...
        uiw.mixin.AxesMouseHandler & uiw.mixin.HasCallback
    % AnnotationViewer - mixin class for an interactive viewer and editor
    % that displays annotation of graphics
    %
    % Notes:
    %
    %
    
    % Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 270 $  $Date: 2018-07-30 09:25:28 -0400 (Mon, 30 Jul 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (AbortSet)
        AllowDragVertex (1,1) logical = false %Set true to enable dragging a vertex to move it
    end %properties
    
    properties (AbortSet, SetAccess=private)
        AnnotationModel (:,1) uiw.model.BaseAnnotationModel % Data model for the annotations
    end %properties
    
    properties (AbortSet, SetAccess=protected)
        SelectedAnnotationModel uiw.model.BaseAnnotationModel % Currently selected annotation
        SelectedVertex double = [] %Selected vertex in the selected annotation
        PendingAnnotationModel uiw.model.BaseAnnotationModel % Currently being added annotation
        IsAddingInteractiveAnnotation (1,1) logical = false %Indicates if an annotation is currently being added interactively
    end %properties
    
    properties (Transient, AbortSet, Access=protected)
        AnnotationParent (1,1) matlab.graphics.Graphics = gobjects(1); % Parent axes for annotations - subclass should set
        AnnotationModelChangedListener event.listener % Listener to AnnotationModel changes
    end %properties
    
    properties (Constant, Access=protected)
       SELECTEDCOLOR = [1 1 0]; 
       EDITINGCOLOR = [0 1 0];
    end
    
    
    %% Public Methods
    methods
        
        function selectAnnotation(obj, aObjIn, clickPoint)
            % Select annotation by index or object
            
            % Defaults
            aObj = uiw.model.BaseAnnotationModel.empty(0,0);
            vIdx = [];
            
            % Clean-up
            obj.removeInvalidAnnotations();
            
            if nargin<2 || isempty(aObjIn)
                set(obj.AnnotationModel,'IsSelected',false);
            else
                
                % Was an object or index provided?
                if isnumeric(aObjIn)
                    validateattributes(aObjIn,{'numeric'},{'scalar','integer','nonnegative','<=',numel(obj.AnnotationModel)})
                    aObj = obj.AnnotationModel(aObjIn);
                    
                elseif isvalid(aObjIn)
                    
                    if ~any( aObjIn == obj.AnnotationModel )
                        error('AnnotationViewer:select:NotInSet',...
                            'The specified annotation is not in the AnnotationModel list.')
                    end
                    
                    aObj = aObjIn;
                    
                else
                    aObj = [];
                end
                
                % Change the selections on the models
                if ~isempty(aObj)
                    isMatch = aObj == obj.AnnotationModel;
                    set(obj.AnnotationModel(~isMatch),'IsSelected',false);
                    set(obj.AnnotationModel( isMatch),'IsSelected',true);
                end
                
                % Was a point clicked to make this selection?
                if nargin>=3 && isa(obj.SelectedAnnotationModel,'uiw.model.PointsAnnotation')
                    
                    % Get the nearest vertex point to the click
                    [~, vIdx] = getNearestVertex(aObj, clickPoint([2 1 3]));
                
                end %if nargin>=3
                
            end %if nargin<2 || isempty(aObjIn)
            
            % Select the model and vertex
            obj.SelectedAnnotationModel = aObj;
            obj.SelectedVertex = vIdx;
            
        end %function
        
        
        function addAnnotation(obj,aObj)
            
            validateattributes(aObj,{'uiw.model.BaseAnnotationModel'},{'nonempty'});
            
            % Remove any invalid annotations
            obj.removeInvalidAnnotations();
            
            % Find any duplicates in the list
            isDupe = ismember(obj.AnnotationModel, aObj);
            
            % Append the list, removing duplicates
            obj.AnnotationModel = vertcat( obj.AnnotationModel(~isDupe), aObj(:) );
            
            % Attach listener to new list
            obj.attachAnnotationModelListener();
            
            % Redraw the new annotations
            obj.redrawAnnotations(aObj);
            
        end %function
    
        
        function aObj = addInteractiveAnnotation(obj,aObj)
            
            % Get the annotation ready
            if nargin>1
                validateattributes(aObj,...
                    {'uiw.model.BaseAnnotationModel'},{'nonempty'});
                aObj.IsBeingEdited = true;
            else
                aObj = uiw.model.PointsAnnotation('IsBeingEdited',true);
            end
            
            % Toggle interactive mode
            obj.IsAddingInteractiveAnnotation = true;
            
            % Add this annotation to the list, so it can be displayed
            obj.addAnnotation(aObj);
            
            % Select the new annotation for editing
            obj.PendingAnnotationModel = aObj;
            
            % Select it in the AnnotatedVolumeViewer also
            obj.selectAnnotation(aObj);
            
        end %function
        
        
        function finishAnnotation(obj)
            % Complete the annotation
            
            if ~obj.IsAddingInteractiveAnnotation
                return
            end
            
            % Turn off interactive mode
            obj.IsAddingInteractiveAnnotation = false;
            
            % Prepare eventdata
            evt = uiw.event.EventData(...
                'EventType','AnnotationAdded',...
                'Model',obj.PendingAnnotationModel);
            
            % Toggle off the editing display
            set(obj.PendingAnnotationModel,'IsBeingEdited',false);
            
            % Remove the pending annotation
            obj.PendingAnnotationModel(:) = [];
            
            % Call method (superclass may override this to do
            % something)
            obj.onInteractiveAnnotationAdded(evt)
            
            % Call callback
            obj.callCallback(evt);
            
        end %function
        
        
        function cancelAnnotation(obj,~)
            
            % Turn off interactive mode
            obj.IsAddingInteractiveAnnotation = false;
            
            if ~isempty(obj.PendingAnnotationModel)
                
                % Remove the selected annotation
                obj.selectAnnotation([]);
                
                % Remove the annotation model
                obj.removeAnnotation( obj.PendingAnnotationModel );
                
                % Remove the pending annotation
                obj.PendingAnnotationModel(:) = [];
            end
            
            
        end %function
        
        
        function removeAnnotation(obj,aObjToRemove)
            % Remove annotation by object
            
            validateattributes(aObjToRemove,{'uiw.model.BaseAnnotationModel'},{'nonempty'});
            
            % Unplot the removed annotations
            for idx = 1:numel(aObjToRemove)
                delete(aObjToRemove(idx).Plot);
                aObjToRemove(idx).Plot = gobjects(0);
            end %for idx = 1:numel(aObjToRemove)
            
            % If the removed annotation was selected, then deselect it
            if any(aObjToRemove == obj.SelectedAnnotationModel)
                 obj.selectAnnotation([]);
            end %if any...        
            
            % Update the list of annotations
            isBeingRemoved = ismember(obj.AnnotationModel, aObjToRemove);
            obj.AnnotationModel(isBeingRemoved) = [];
            
        end %function
        
    end %methods
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function redrawAnnotations(obj,aObj)
            % Redraw the specified annotations completely
            
            % Check inputs
            if nargin<2
                aObj = obj.AnnotationModel;
            end
            
            % Clean-up
            obj.removeInvalidAnnotations();
            
            % Perform the plotting
            for idx = 1:numel(aObj)
                
                if isa(aObj(idx),'uiw.model.MaskAnnotation')
                    obj.redrawMaskAnnotation(aObj(idx));
                elseif isa(aObj(idx),'uiw.model.PointsAnnotation')
                    obj.redrawPointsAnnotation(aObj(idx));
                end %if isa(aObj(idx),'uiw.model.MaskAnnotation')
                
            end %for idx = 1:numel(aObj)
            
        end %function
        
        
        function createPointsAnnotation(obj,aObj)
            % Create the graphics objects to plot a polygon annotation
            
            aObj.Plot = matlab.graphics.primitive.Patch(...
                'Parent',obj.AnnotationParent,...
                'LineWidth', 1,...
                'FaceColor','none',...
                'EdgeColor','interp',...
                'EdgeAlpha','interp',...
                'AlphaDataMapping','none',...
                'AlignVertexCenters','on',...
                'MarkerFaceColor','flat',...
                'UserData',aObj);
            
            % Special case for line/points annotations
            if isa(aObj,'uiw.model.PolygonAnnotation')
                aObj.Plot.FaceColor = 'interp';
                aObj.Plot.FaceAlpha = 'interp';
            elseif isa(aObj,'uiw.model.LineAnnotation')
                % do nothing
            elseif isa(aObj,'uiw.model.PointsAnnotation')
                aObj.Plot.LineStyle = 'none';
            end
            
        end %function
        
        
        function redrawPointsAnnotation(obj,aObj)
            % Update the graphics objects to plot a single annotation
            
            % Does the graphics object exist?
            if ~aObj.HasLine
                obj.createPointsAnnotation(aObj)
            end
            
            
            % Check visibility
            isVisible = aObj.ShowObject && aObj.IsVisible;
            
            % Draw only if visible
            if isVisible
                
                % Calculate the data to update the plot
                [data,color,alpha] = obj.getPointsAnnotationPlotData(aObj);
                
                % Marker is different when selected
                if aObj.IsBeingEdited
                    lineWidth = aObj.LineWidth;
                    marker = '+';
                    markerSize = 10;
                    markerEdgeColor = obj.EDITINGCOLOR;
                elseif aObj.IsSelected
                    lineWidth = 2;
                    marker = 'o';
                    markerSize = 8;
                    markerEdgeColor = obj.SELECTEDCOLOR;
                else
                    lineWidth = 2;
                    marker = 'o';
                    markerSize = 6;
                    markerEdgeColor = 'none';
                end
                
                % Update the plot
                set(aObj.Plot,...
                    'LineWidth',lineWidth,...
                    'Marker',marker,...
                    'MarkerSize',markerSize,...
                    'MarkerEdgeColor',markerEdgeColor,...
                    'Vertices',data(:,[2 1 3]),...
                    'Faces',1:size(data,1),...
                    'FaceVertexAlphaData',alpha,...
                    'FaceVertexCData',color )
                
            end %if isVisible
            
            % Toggle visibility
            aObj.Plot.Visible = isVisible;
            
        end %function
        
        
        function [data,color,alpha] = getPointsAnnotationPlotData(~,aObj)
            % Calculate the data to update the plot
            
            % Get the data
            data = aObj.Points;
            color = repmat(aObj.Color, size(data,1), 1);
            alpha = repmat(aObj.Alpha, size(data,1), 1);
            
            % Special case for non-polygon annotations
            if ~isa(aObj,'uiw.model.PolygonAnnotation')
                
                % Append a NaN vertex so the face is not drawn
                data = vertcat(data, nan(1,3));
                color = vertcat(color, nan(1,3));
                alpha = vertcat(alpha, nan);
                
            end %if isa(aObj,'uiw.model.LineAnnotation') || ...
            
        end %function
        
        
        function createMaskAnnotation(obj,aObj)
            % Create the graphics objects to plot a mask annotation
            
            aObj.Plot = matlab.graphics.primitive.Surface(...
                'Parent',obj.AnnotationParent,...
                'PickableParts','none',...
                'Marker','none',...
                'LineStyle','none',...
                'FaceColor','texturemap',...
                'FaceAlpha','texturemap',...
                'AlphaDataMapping','none',...
                'AlignVertexCenters','on',...
                'CDataMapping','direct',...
                'XData',[], ...
                'YData',[], ...
                'ZData',[], ...
                'CData',[],...
                'AlphaData',[],...
                'UserData',aObj,...
                'EdgeColor','none');    
            
        end %function
        
        
        function redrawMaskAnnotation(obj,aObj)
            % Update the graphics objects to plot a single annotation
            
            % Does the graphics object exist?
            if ~aObj.HasLine
                obj.createMaskAnnotation(aObj)
            end
            
            % Check visibility
            isVisible = aObj.ShowObject && aObj.IsVisible;
            
            % Draw only if visible
            if isVisible
                
                % Calculate the data to update the plot
                [x,y,z,c,a] = obj.getMaskPlotData(aObj);
                
                % Update the plot
                aObj.Plot.XData = x;
                aObj.Plot.YData = y;
                aObj.Plot.ZData = z;
                aObj.Plot.CData = c;
                aObj.Plot.AlphaData = a;
                
            end %if isVisible
            
            % Toggle visibility
            aObj.Plot.Visible = isVisible;
            
        end %function
        
        
        function [x,y,z,c,a] = getMaskPlotData(~,~)
            % Calculate the data to update the plot
            % [x,y,z,c,a] = getMaskPlotData(obj,aObj)
            
            % Do nothing for now - overridden by subclass
            x = [];
            y = [];
            z = [];
            c = [];
            a = [];
            
        end %function
        
        
        function onAnnotationModelChanged(obj,evt)
            % Handle changes to an AnnotationModel - subclass may override
            
            % Redraw all
            obj.redrawAnnotations(evt.Source);
            
        end %function
        
        
        function onInteractiveAnnotationAdded(~,~)
            % Triggered on interactive annotation added - subclass may override
            
        end %function
        
        
        function addPointAt(obj,pos)
            % Add the point to the annotation - subclass may override
            
            if obj.IsAddingInteractiveAnnotation
                obj.PendingAnnotationModel.addPoint(pos);
            end
            
        end %function
        
        
        function onMousePress(obj,evt)
            % Triggered on mouse button down
            
            hHit = evt.HitObject;
            
            if obj.IsAddingInteractiveAnnotation
                % We are adding points to an annotation
                
                % What type of click occurred?
                switch evt.SelectionType
                    
                    case 'normal'
                        % Regular left-click: Draw
                        aObj = obj.SelectedAnnotationModel;
                        if isa(aObj,'uiw.model.PointsAnnotation')
                            
                            % Add a new point
                            pos = evt.AxesPoint([2 1 3]);
                            obj.addPointAt(pos)
                            
                        elseif isa(aObj,'uiw.model.MaskAnnotation')
                            
                            % nothing - continuous draw when dragging
                            
                        end
                        
                    case 'open'
                        % Double-click: Complete the annotation
                        obj.finishAnnotation()
                        
                end %switch
                
            else
                % We're not adding points to an annotation
                
                % Was an existing annotation hit?
                if obj.isAnnotationPlot(hHit)
                    aObj = hHit.UserData;
                else
                    % Nothing was hit - selection empty
                    aObj = uiw.model.BaseAnnotationModel.empty(0);
                end %if obj.isAnnotationPlot(hHit)
                
                % Update the selection
                obj.selectAnnotation(aObj,evt.AxesPoint);
                
            end %if obj.IsAddingInteractiveAnnotation
            
        end %function

        
        function onMouseRelease(~,~)
            % Triggered on mouse button up
            
            
        end %function
        
        
        function onMouseDrag(obj,evt)
            % Triggered on mouse dragged
            % Note this is overridden in some viewers
            
            aObj = obj.SelectedAnnotationModel;
            vIdx = obj.SelectedVertex;
            if obj.AllowDragVertex && ~isempty(aObj) && ~isempty(vIdx)
                newPos = evt.AxesPoint([2 1 3]);
                aObj.Points(vIdx,:) = newPos;
            end
            
        end %function
        
        
        function tf = isAnnotationPlot(~,plotObj)
            % Checks if the specified graphics object is an annotation plot
            
            tf = isscalar(plotObj) && ishghandle(plotObj) && ...
                isprop(plotObj,'UserData') && isscalar(plotObj.UserData) && ...
                isa(plotObj.UserData,'uiw.model.BaseAnnotationModel');
            
        end %function
        
        
        function varargout = removeInvalidAnnotations(obj,aObj)
            
            if nargin > 1
                varargout{1} = aObj(isvalid(aObj));
            end
            
            obj.AnnotationModel(~isvalid(obj.AnnotationModel)) = [];
            
        end %function
        
    end %methods
    
    
    
    %% Private Methods
    methods (Access=private)
        
        function attachAnnotationModelListener(obj)
            
            % Listen to changes in AnnotationModel
            obj.AnnotationModelChangedListener = event.listener(obj.AnnotationModel,...
                'ModelChanged',@(h,e)onAnnotationModelChanged(obj,e) );
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        function set.AnnotationParent(obj,value)
            obj.AnnotationParent = value;
            aObj = obj.AnnotationModel;
            hasLine = [aObj.HasLine];
            set([aObj(hasLine).Plot],'Parent',value);
        end %function
        
    end %methods
    
end % classdef