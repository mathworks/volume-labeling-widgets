classdef Vertices < wt.tool.BaseAnnotationTool
    % Annotation tool for placing vertices in a 2D or 3D view
    
    % Copyright 2020-2023 The MathWorks, Inc.
    
    
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
    
    
    properties (Constant, Access = private)
        
        % Custom pointer during edit
        EditingPointer = getEditingPointer();
        EditingPointerCenter = [16 16]
        
    end %properties
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function onMousePress(obj,evt)
            % Triggered on mouse button down
            
            % Get the click location
            p1 = evt.CurrentPoint([2 1 3]);
                
            % What type of click?
            switch evt.SelectionType
                
                case 'open' % Double-click
                    
                    % Stop the annotation
                    obj.stop()
                    obj.AnnotationModel.IsBeingEdited = false;
                    
                case 'normal' % Left-click
                    
                    % If over an existing point, drag it. Otherwise, add a
                    % new point

                    % Was the click on the object?
                    if any(evt.HitObject == [obj.AnnotationModel.Plot])

                        % Select the closest vertex
                        [~,obj.SelectedVertex] = ...
                            obj.AnnotationModel.getNearestVertex(p1);

                    else

                        % Add the clicked point
                        obj.AnnotationModel.addPoint(p1);
                        obj.SelectedVertex = size(obj.AnnotationModel.Points,1);
                        
                    end
                    
                case 'alt' % Right-click or Ctrl-Left-click
                    
                    % If over an existing point, delete it
                    
                    % Was the click on the object?
                    if evt.HitObject == obj.AnnotationModel.Plot(1)
                        
                        % Locate the closest vertex
                        [~,vIdx] = obj.AnnotationModel.getNearestVertex(p1);
                        
                        % Delete it
                        obj.AnnotationModel.Points(vIdx,:) = [];
						
                        % Hide the associated label
                        ax = obj.ClickableAxes;
                        labelTag = 'Control Point Label';
                        hLabel = findall(ax, 'Tag',labelTag);
                        set(hLabel,'Visible','off');
                        
                    end
                    
                case 'extend' % Shift-left-click
                    
                    % Always add the new point, even if it's over an
                    % existing one

                        % Add the clicked point
                        obj.AnnotationModel.addPoint(p1);
                    
            end %switch evt.SelectionType
            
        end %function
        
        
        function onMouseRelease(obj,evt)
            % Triggered on mouse released
            
            % If a point was being dragged, update it one last time
            % This is necessary if the last action was mouse wheel to
            % change slice, rather than further dragging
            if ~isempty(obj.SelectedVertex)
                pos = evt.CurrentPoint([2 1 3]);
                obj.updateAnnotationPoint(pos);
            end %if
            
            obj.SelectedVertex = [];            
            
        end %function
        
        function onMouseMotion(obj,evt)  %Yair
            % Triggered on mouse movement
            
            % If we are hovering over a vertex
            ax = obj.ClickableAxes;
            labelTag = 'Control Point Label';
            hLabel = findall(ax, 'Tag',labelTag);
            if obj.CurrentHitObject == obj.AnnotationModel.Plot(1)
                % Get the BaseModelPanel object used below
                hPanel = getappdata(ax, 'modelPanel');
                if isempty(hPanel), return, end

                % Locate the closest vertex
                %ax.CurrentPoint is inaccurate in 3D, so use evt.IntersectionPoint
                p1 = evt.IntersectionPoint([2,1,3]);
                [~,vIdx] = obj.AnnotationModel.getNearestVertex(p1);

                % Display updated label with the vertex name
                pos = evt.IntersectionPoint; % * 1.01;  %slight offset from vertex
                if isempty(hLabel)
                    hLabel = text(ax, pos(1),pos(2),pos(3),'', 'Tag',labelTag, ...
                                  'HitTest','off', 'PickableParts','none', ...
                                  'Color','y', 'BackgroundColor',[0,0,0,.2], ...
                                  'Layer','Front', 'FontWeight','bold');
                end
                str = hPanel.ExplanatoryLabel.Text;
                str = regexprep(str, ['.* ' num2str(vIdx) '\.([^\n]+).*'], '\\leftarrow$1');
                hLabel.String = str;
                hLabel.Position = pos;
                hLabel.Visible = 'on';
            else
                % Hide the label
                if ~isempty(hLabel)
                    hLabel.Visible = 'off';
                end
            end
            
        end %function
        
        function updatePointer(obj)
            % Update the mouse pointer
            ax = obj.ClickableAxes;
            if obj.IsDragging || any(obj.CurrentHitObject == [obj.AnnotationModel.Plot])

                wt.utility.fastSet(obj.CurrentFigure,"Pointer","fleur")

                % Disable built-in interactivity
                disableDefaultInteractivity(ax); 
				
                % these were taken from matlab.graphics.interaction.webmodes.toggleMode
                ax.InteractionContainer.clearList
                try 
                    ax.InteractionContainer.CurrentMode = 'none'; 
                catch
                end
                ax.InteractionContainer.updateInteractions();
                oldPos = get(groot,'PointerLocation');
                set(groot,'PointerLocation',[0,0]); pause(0.001)
                set(groot,'PointerLocation',oldPos);
				
            elseif obj.CurrentFigure.Pointer ~= "custom"

                set(obj.CurrentFigure,...
                    "Pointer","custom",...
                    "PointerShapeCData",obj.EditingPointer,...
                    "PointerShapeHotSpot",obj.EditingPointerCenter);

                % Re-enable built-in interactivity
                enableDefaultInteractivity(ax); 
                ax.InteractionContainer.updateInteractions();
                drawnow

            end %if obj.IsDragging
            
        end %function
        
        
        function onMouseDrag(obj,evt)
            % Triggered on mouse dragged
            
            % If a point is being dragged, update it
            if ~isempty(obj.SelectedVertex)
                obj.updateAnnotationPoint( evt.CurrentPoint([2 1 3]) );
            end %if
            
        end %function
        
        
        function updateAnnotationPoint(obj,pos)
            % Updates the position of the annotation point being modified
            
            % For 2D views, adjust the click point to pixel centers
            mPos = mean(obj.AnnotationModel.SliceRangeFilter, 2);
            isSliceDim = ~isnan(mPos);
            pos(isSliceDim) = mPos(isSliceDim);
            
            % Update the vertex position
            vIdx = obj.SelectedVertex;
            obj.AnnotationModel.Points(vIdx,:) = pos;
            
        end %function
        
    end %methods
    
end % classdef



%% Helper Functions
function ptr = getEditingPointer()

ptr = [
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    1	1	1	1	1	1	1	1	1	1	1	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	1	1	1	1	1	1	1	1	1	1	1	NaN
    2	2	2	2	2	2	2	2	2	2	2	2	NaN	NaN	NaN	NaN	NaN	NaN	NaN	2	2	2	2	2	2	2	2	2	2	2	2	NaN
    2	2	2	2	2	2	2	2	2	2	2	2	NaN	NaN	NaN	2	NaN	NaN	NaN	2	2	2	2	2	2	2	2	2	2	2	2	NaN
    2	2	2	2	2	2	2	2	2	2	2	2	NaN	NaN	NaN	NaN	NaN	NaN	NaN	2	2	2	2	2	2	2	2	2	2	2	2	NaN
    1	1	1	1	1	1	1	1	1	1	1	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	1	1	1	1	1	1	1	1	1	1	1	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	2	2	2	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    ];

end %function