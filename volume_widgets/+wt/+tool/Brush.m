classdef Brush < wt.tool.BaseAnnotationTool
    % Brush tool for editing a mask annotation
    
    % Copyright 2020 The MathWorks, Inc.
    
    
    %% Properties
    properties (AbortSet)
        
        % The diameter of the brush in pixels, should be an odd number
        BrushSize (1,1) double {mustBeInteger, mustBePositive, mustBeFinite} = 5
        
    end %properties
    
    
    properties (SetAccess = protected)
        
        % The annotation being edited
        AnnotationModel
        
    end %properties
    
    
    %% Internal Properties
    properties (Access = protected)
        
        % The pixel mask for the brush (NxN matrix for N BrushSize)
        BrushMask (:,:) logical = true
        
        % The brush indicator
        BrushIndicator (1,1) matlab.graphics.primitive.Patch
        
        % Transform for the brush indicator 
        BrushTransform (1,1) matlab.graphics.primitive.Transform
        
    end %properties
    
    
    properties (Constant, Access = private)
        
        % Custom pointer during edit
        EditingPointer = getEditingPointer()
        EditingPointerCenter = [16 16]
        %EditingPointerCenter = [20 20]
        
    end %properties
    
    
    %% Constructor and Destructor
    methods
        
        % Constructor
        function obj = Brush()
            % Construct the tool
            
            % Create brush indicator
            theta = linspace(0, 2*pi)';
            x = 0.5 * cos(theta);
            y = 0.5 * sin(theta);
            %c = 0.5 * ones(numel(theta),3);
            %c(1:2:end, 1:2) = 1;
            obj.BrushTransform = hgtransform("Parent",[]);
            obj.BrushIndicator = patch(...
                "Parent",obj.BrushTransform,...
                "XData",x,...
                "YData",y,...
                "ZData",zeros(size(x)),...
                "XLimInclude","off",...
                "YLimInclude","off",...
                "ZLimInclude","off",...
                "LineWidth",2,...
                "LineStyle","-",...
                "FaceColor","none",...
                "EdgeColor",[.5 1 .5],...
                "EdgeAlpha",0.3);
            %"FaceVertexCData",c,...
            %"EdgeColor","flat",...
            
            % Adjust defaults
            obj.updateBrushMask();
            
        end %function
        
    end %methods
    
    
    %% Public Methods
    methods
        
        function invert(obj,varargin)
            % Inverts the mask
            
            obj.AnnotationModel.invert(varargin{:});
            
        end %function
        
    end %methods
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function onMousePress(obj,evt)
            % Triggered on mouse button down
            
            % Get the click location
            p1 = evt.CurrentPoint([2 1 3]);
            
            % What type of click?
            switch evt.SelectionType
                
                case 'normal'
                    
                    % Erase?
                    erase = obj.Erase;
                    
                    % Apply the mask and brush size
                    obj.applyPointerTrailToMask(p1,[],erase);
                    
                case 'alt'
                    
                    % Erase?
                    erase = ~obj.Erase;
                    
                    % Apply the mask and brush size
                    obj.applyPointerTrailToMask(p1,[],erase);
                    
                case 'open'
                    
                    % Stop the annotation
                    obj.stop()
                    obj.AnnotationModel.IsBeingEdited = false;
                    
            end
            
        end %function
        
        
        function onMouseDrag(obj,evt)
            % Triggered on mouse dragged
            
            % Get the drag location and distance
            p1 = evt.StartPoint([2 1 3]);
            p2 = evt.CurrentPoint([2 1 3]);
            
            % What type of click?
            switch evt.SelectionType
                
                case 'normal'
                    
                    % Erase?
                    erase = obj.Erase;
                    
                    % Apply the mask and brush size
                    obj.applyPointerTrailToMask(p1,p2,erase);
                    
                case 'alt'
                    
                    % Erase?
                    erase = ~obj.Erase;
                    
                    % Apply the mask and brush size
                    obj.applyPointerTrailToMask(p1,p2,erase);
                    
            end
            
        end %function
        
        
        function onStart(obj)
            % Triggered on edit start

            % Parent the brush indicator
            obj.BrushTransform.Parent = obj.ClickableAxes;
            
        end %function
        
        
        function onStop(obj)
            % Triggered on edit stop
            
            % Unparent the brush indicator
            obj.BrushTransform.Parent = [];
            
        end %function
        
        
        function onMouseMotion(obj,evt)
            % Triggered on mouse moving
            
            % Get the current point
            pos = evt.IntersectionPoint;
            
            % Update the brush indicator position
            obj.BrushTransform.Matrix(1:3,4) = pos;
            
        end %function
        
        
        function updatePointer(obj)
            % Update the mouse pointer

            if obj.CurrentFigure.Pointer ~= "custom"

                set(obj.CurrentFigure,...
                    "Pointer","custom",...
                    "PointerShapeCData",obj.EditingPointer,...
                    "PointerShapeHotSpot",obj.EditingPointerCenter);

            end %if obj.IsDragging

        end %function

        
        function applyPointerTrailToMask(obj,p1,p2,erase)
            % Interpolate pixel coordinates between two points
            
            % Get the annotation
            aObj = obj.AnnotationModel;
            
            % Get the pixel coordinates
            px1 = cell2mat(obj.AnnotationModel.getSliceIndex(p1));
            
            % Return if invalid point
            if any(ismissing(px1))
                return
            end
            
            % Is this a segment or single point?
            if isempty(p2)
                % Just a single point
                
                pxCoords = px1;
                
            else
                % It's a segment
                
                % Get the second point
                px2 = cell2mat(obj.AnnotationModel.getSliceIndex(p2));
                
                % Return if invalid point
                if any(ismissing(px2))
                    return
                end
                
                % Find number of points to draw between mouse locations
                numInterp = max(abs(px2 - px1)) + 1;
                
                % Calculate the interpolated points
                pxCoords = zeros(numInterp, numel(px1));
                for idx = 1:numel(px1)
                    pxCoords(:,idx) = round(linspace(px1(idx),px2(idx),numInterp));
                end
                
            end %if isempty(p2)
            
            % Which dimension is 2D slices?
            view = obj.ClickableAxes.View;
            if all(view == [0 -90]) %XY view
                sliceDim = 3;
            elseif all(view == [0 0]) %XZ view
                sliceDim = 1;
            elseif all(view == [-90 0]) %YZ view
                sliceDim = 2;
            else
                sliceDim = [];
            end %if
            
            % Preallocate an empty 2D mask for optimal performance
            maskSize = aObj.DataSize;
            maskSize(sliceDim) = [];
            drawnMask = false(maskSize(:)');

            % Remove the slice dimension from the coordinates
            maskCoords = {':',':',':'};
            if ~isempty(sliceDim)
                sliceIdx = pxCoords(1,sliceDim);
                maskCoords{sliceDim} = sliceIdx;
                pxCoords(:,sliceDim) = [];
            end
            
            % Calculate mask for this point or segment
            pxCoordsCell = num2cell(pxCoords);
            for idx = 1:size(pxCoordsCell,1)
                drawnMask(pxCoordsCell{idx,:}) = true;
            end
            
            % Apply brush size
            if obj.BrushSize > 1
                drawnMask = imdilate(drawnMask,obj.BrushMask,'same');
            end
            
            % Get the old mask
            maskSection = squeeze(obj.AnnotationModel.Mask(maskCoords{:}));
            
            % Are we erasing or brushing?
            if erase
                % Erase brushed area
                maskSection = maskSection & ~drawnMask;
            else
                % Add brushed area
                maskSection = maskSection | drawnMask;
            end
            
            % Update the mask
            obj.AnnotationModel.Mask(maskCoords{:}) = maskSection;
            
        end %function
        
        
        function updateBrushMask(obj)
            % Calculate the brush mask
            
            if obj.BrushSize == 2
                brushMask = true(2,2);
            elseif mod(obj.BrushSize,2)
                brushMask = false(obj.BrushSize);
                midPt = ceil(obj.BrushSize/2);
                brushMask(midPt,midPt) = true;
            else
                brushMask = false(obj.BrushSize+1);
                midPt = ceil(obj.BrushSize/2) + 1;
                brushMask(midPt,midPt) = true;
            end
            obj.BrushMask = bwdist(brushMask) < obj.BrushSize/2;
            
            % Update the brush indicator's size
            obj.BrushTransform.Matrix([1 6 11]) = obj.BrushSize + 2;
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        function set.BrushSize(obj,value)
            obj.BrushSize = value;
            obj.updateBrushMask();
        end
        
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
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    1	1	1	1	1	1	1	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	1	1	1	1	1	1	1	NaN
    2	2	2	2	2	2	2	2	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	2	2	2	2	2	2	2	2	NaN
    2	2	2	2	2	2	2	2	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	2	2	2	2	2	2	2	2	NaN
    2	2	2	2	2	2	2	2	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	2	2	2	2	2	2	2	2	NaN
    1	1	1	1	1	1	1	1	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	1	1	1	1	1	1	1	1	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
    NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN	NaN
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