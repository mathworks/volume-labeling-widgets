classdef (Hidden) AnnotatedVolumeViewer < uiw.widget.VolumeViewer ...
        & uiw.mixin.AnnotationViewer
    % AnnotatedVolumeViewer -
    %
    %
    % 
    % Syntax:
    %       obj = AnnotatedVolumeViewer
    %       obj = AnnotatedVolumeViewer('Property','Value',...)
    %
    % Notes:
    %
    %
    
    % Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 297 $  $Date: 2018-09-05 15:55:42 -0400 (Wed, 05 Sep 2018) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (AbortSet)
        ShowAllSliceAnnotations (1,1) logical = true %Show all annotations (except masks) regardless of current slice
    end %properties
    
    
    %% Internal Properties
    properties (SetAccess = protected)
        SlicePosition (1,1) double = 0 %midpoint position of current slice
        SliceRange (1,2) double = [0 0]; %position range of current slice
    end
    properties (Access = protected)
        AnnotationPosition (1,1) double = 0 %position to draw annnotations
    end
    
    %% Constructor / destructor
    methods
        
        function obj = AnnotatedVolumeViewer(varargin)
            % Construct the control
            
            % Call superclass constructor
            obj = obj@uiw.widget.VolumeViewer(varargin{:});
            
            % Assign AnnotationParent axes
            obj.AnnotationParent = obj.h.Axes;
            
            % Assign clickable axes
            obj.ClickableAxes = obj.h.Axes;
            
        end %constructor
        
    end %methods
    
    
    
    %% Public Methods
    methods
        
        % Override
        function selectAnnotation(obj, aObjIn, clickPoint)
            % Select annotation by index or object
            
            % Call superclass method
            obj.selectAnnotation@uiw.mixin.AnnotationViewer(aObjIn);
            
            % The annotation selected
            aObj = obj.SelectedAnnotationModel;
                
            % Jump to slice of the selection and nearest vertex in 2D slice
            if nargin>=3 && ~isempty(aObj) && sum(obj.SliceDimension)==1 ...
                    && isa(aObj,'uiw.model.PointsAnnotation')
                
                % Select the closest vertex in 2D space
                isSliceDim = obj.SliceDimension;
                [vertex, vIdx] = getNearestVertex(aObj, ...
                    clickPoint([2 1 3]), isSliceDim);
                
                % Store the selected vertex index
                obj.SelectedVertex = vIdx;
                
                % Jump to the nearest slice
                sliceIndex = obj.VolumeModel.getSliceIndex(vertex);
                obj.Slice = sliceIndex{isSliceDim};
                
            else
                % No vertex was selected
                obj.SelectedVertex = [];
                
            end %if ~isempty(obj.SelectedAnnotationModel)
            
        end %function
        
    end %methods
    
    
    
    %% Protected Methods
    methods (Access = protected)
        
        %Override
        function redrawSliceSelection(obj)
            % Handle state changes that may need UI redraw
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Call superclass method
                obj.redrawSliceSelection@uiw.widget.VolumeViewer();
                
                % Calculate slice positioning (for annotations)
                obj.SliceRange = obj.VolumeModel.getSliceRange(...
                    obj.SliceDimension, obj.Slice);
                obj.SlicePosition = mean(obj.SliceRange);
                offset = diff(obj.SliceRange)/100;
                obj.AnnotationPosition = mean(obj.SliceRange) - offset;
                
                % Are we showing all annotations regardless of slice?
                if obj.ShowAllSliceAnnotations
                    
                    % Show everything
                    set(obj.AnnotationModel,'ShowObject',true);
                    
                else
                    % Show only annotations with a point in this slice
                    
                    for idx = 1:numel(obj.AnnotationModel)
                        
                        % Get the current annotation
                        aObj = obj.AnnotationModel(idx);
                        
                        % Is it a points annotation?
                        if isa(aObj,'uiw.model.PointsAnnotation')
                            
                            % Get the points
                            data = aObj.Points;
                            
                            % Which points are in the current slice
                            viewDim = obj.SliceDimension;
                            inSlice = data(:,viewDim) >= obj.SliceRange(1) & ...
                                data(:,viewDim) <= obj.SliceRange(2);
                            
                            % Show annotation if any are in slice
                            aObj.ShowObject = any(inSlice);
                            
                        end %if isa(aObj,'uiw.model.PointsAnnotation')
                        
                    end %for idx = 1:numel(obj.AnnotationModel)
                    
                end %if obj.ShowAllSliceAnnotations
                
                % Redraw annotations
                % (implemented in uiw.mixin.AnnotationViewer)
                obj.redrawAnnotations();
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function [data,color,alpha] = getPointsAnnotationPlotData(obj,aObj)
            % Calculate the data to update the plot
            
            % Call superclass method
            [data,color,alpha] = getPointsAnnotationPlotData@...
                uiw.mixin.AnnotationViewer(obj,aObj);
            
            % Which points are in the current slice
            viewDim = obj.SliceDimension;
            inSlice = data(:,viewDim) >= obj.SliceRange(1) & ...
                data(:,viewDim) <= obj.SliceRange(2);
            
            % Dim color/alpha
            color(~inSlice,:) = color(~inSlice,:) * 0.7;
            alpha(~inSlice,:) = alpha(~inSlice,:) * 0.7;
            
            % Update data for slice dimension
            data(:,viewDim) = obj.AnnotationPosition;
            
        end %function
        
        
        function [x,y,z,c,a] = getMaskPlotData(obj,aObj)
            % Calculate the data to update the plot
            
            % Sanity check
            if obj.Slice > aObj.DataSize( obj.SliceDimension )
                x = [];
                y = [];
                z = [];
                c = [];
                a = [];
                return;
            end
            
            % Get indices into the selected slice
            sliceIdxNum = nan(1,3);
            sliceIdxNum(obj.SliceDimension) = obj.Slice;
            %slicePosNum = nan(1,3);
            %slicePosNum(obj.SliceDimension) = obj.SlicePosition;
            maskIndices = {':',':',':'};
            maskIndices{obj.SliceDimension} = obj.Slice;
            
            % Get the mask for this slice
            mask = squeeze( aObj.Mask(maskIndices{:}) );
            
            % Get the position of the mask's slice
            [x,y,z, isTranspose] = aObj.getSliceXYZ(sliceIdxNum);
            
            if isTranspose()
              mask=mask';
            end
            
            % Prepare the color data as the mask
            c = zeros([size(mask) 3]);
            c(:,:,1) = mask * aObj.Color(1);
            c(:,:,2) = mask * aObj.Color(2);
            c(:,:,3) = mask * aObj.Color(3);
            
            % Prepare the alpha data
            a = mask * aObj.Alpha;
            
        end %function
        
        
        % Override
        function onMouseDrag(obj,evt)
            % Triggered on mouse dragged
            
            % What kind of annotation is selected?
            aObj = obj.SelectedAnnotationModel;
            if isempty(aObj)
                % Do nothing
                
            elseif isa(aObj,'uiw.model.PointsAnnotation') && ...
                    obj.AllowDragVertex && ~isempty(obj.SelectedVertex)
                % It's a polygon/line/points and is draggable
                
                % Drag the vertex
                newPos = evt.AxesPoint([2 1 3]);
                inSlice = ~obj.SliceDimension;
                aObj.Points(obj.SelectedVertex,inSlice) = newPos(inSlice);
                
            elseif isa(aObj,'uiw.model.MaskAnnotation')
                % It's a mask that's drawable
                
                % Get the indices
                pos = evt.AxesPoint([2 1 3]);
                indices = aObj.getSliceIndex(pos);
                
                % Expand brush size here?
                
                % Also need to extend line from previous point to current,
                % so the mouse doesn't skip points                
                
                % Update the mask
                aObj.Mask(indices{:}) = true;
                
            end
            
        end %function
        
    end %methods
    
    
    
    
    
    %% Get/Set Methods
    methods
        
        function set.ShowAllSliceAnnotations(obj,value)
            obj.ShowAllSliceAnnotations = value;
            obj.redrawSliceSelection();
        end %function
        
    end %methods
    
end % classdef