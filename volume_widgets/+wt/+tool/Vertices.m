classdef Vertices < wt.tool.BaseAnnotationTool
    % Annotation tool for placing vertices in a 2D or 3D view
    
    % Copyright 2020 The MathWorks, Inc.
    
    
    %% Properties
    properties (SetAccess = protected)
        
        % The annotation being edited
        AnnotationModel %wt.model.PointsAnnotation {mustBeScalarOrEmpty}
        
    end %properties
    
    
    %% Internal Properties
    properties (Access = protected)
        
        % The pixel mask for the Vertices (NxN matrix for N VerticesSize)
        VerticesMask logical = true
        
        % The selected vertex for dragging
        SelectedVertex double
        
    end %properties
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function onMousePress(obj,evt)
            % Triggered on mouse button down
            
            % Get the click location
            p1 = evt.CurrentPoint([2 1 3]);
%             
%             % For debug - what was hit?            
%             if isempty(evt.HitObject)
%                 disp('empty');
%             elseif isempty(evt.HitObject.UserData)
%                 disp(class(evt.HitObject));
%             elseif isprop(evt.HitObject.UserData,'Name')
%                 disp(evt.HitObject.UserData.Name);
%             else
%                 disp(class(evt.HitObject.UserData));
%             end
                
                
            % What type of click?
            switch evt.SelectionType
                
                case 'open' % Double-click
                    
                    % % First, delete any extra vertex that was added during the
                    % % first part of the double-click.
                    %
                    % % Locate the closest vertex
                    % [~,vIdx] = obj.AnnotationModel.getNearestVertex(p1);
                    %
                    % % Delete it
                    % obj.AnnotationModel.Points(vIdx,:) = [];
                    
                    % Stop the annotation
                    obj.stop()
                    obj.AnnotationModel.IsBeingEdited = false;
                    
                case 'normal' % Left-click
                    
                    % Add the clicked point
                    obj.AnnotationModel.addPoint(p1);
                    
                case 'alt' % Right-click or Ctrl-Left-click
                    
                    % Was the click on the object?
                    if any(evt.HitObject == [obj.AnnotationModel.Plot])
                        
                        % Select the closest vertex
                        [~,obj.SelectedVertex] = ...
                            obj.AnnotationModel.getNearestVertex(p1);
                        
                    end
                    
                case 'extend' % Shift-left-click
                    
                    % Was the click on the object?
                    if any(evt.HitObject == [obj.AnnotationModel.Plot])
                        
                        % Locate the closest vertex
                        [~,vIdx] = obj.AnnotationModel.getNearestVertex(p1);
                        
                        % Delete it
                        obj.AnnotationModel.Points(vIdx,:) = [];
                        
                    end
                
            end %switch evt.SelectionType
            
        end %function
        
        
        function onMouseRelease(obj,~)
            % Triggered on mouse released
            
            obj.SelectedVertex = [];            
            
        end %function
        
        
        function onMouseDrag(obj,evt)
            % Triggered on mouse dragged
            
            if ~isempty(obj.SelectedVertex) && strcmp(evt.SelectionType,'alt')
                
                % Get the current location
                p1 = evt.CurrentPoint([2 1 3]);
                
                % Update the vertex position
                vIdx = obj.SelectedVertex;
                obj.AnnotationModel.Points(vIdx,:) = p1;
                
            end %if
            
        end %function
        
    end %methods
    
end % classdef