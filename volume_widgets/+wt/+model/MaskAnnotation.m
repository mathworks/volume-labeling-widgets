classdef MaskAnnotation < wt.model.BaseAnnotationModel ...
        & wt.model.Base3DImageryModel
    % Annotation with Y,X,Z coordinate points connected as a filled shape
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    
    %% Public Properties
    properties (AbortSet, SetObservable)
        
        % The binary mask in 3D space
        Mask (:,:,:) logical 
        
    end %properties
    
    
    %% Internal Properties
    
    properties (SetAccess = protected)
        
        % What is the default editing tool for the annotation?
        EditingTool = 'wt.tool.Brush'
        
        % Indicates all points are in the same plane
        AllInCoordinatePlane (1,3) logical
        
    end
    
    
    
    %% Static Methods
    methods (Static)
        
        function obj = fromVolumeModel(vObj,varargin)
            % Create a mask matching a volume model
            
            % Validate input
            validateattributes(vObj,{'wt.model.VolumeModel'},{'scalar'})
            
            % Create the object
            % Set up the mask to match the volume
            obj = wt.model.MaskAnnotation(...
                'WorldExtent',vObj.WorldExtent,...
                'Mask',false(size(vObj.ImageData)),...
                varargin{:});
            
        end %function
        
    end %methods
    
    
    
    %% Public Methods
    methods
        
        function invert(obj,sliceDim)
            % Inverts the mask
            
            if nargin>=2
                obj.Mask(sliceDim{:}) = ~obj.Mask(sliceDim{:});
            else
                obj.Mask = ~obj.Mask;
            end
            
        end %function
        
    end %methods
    
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function createOne(obj,parent)
            
            % Create the surface plot for the mask Turn off HitTest - it
            % should never be clickable because it isn't edited that way
            % and clicks still hit any part of the surface even if
            % PickableParts is set to 'visible'.
            
            %Marker doesn't really work on mask annotation, because we're
            %displaying as a surface we just see marker points at every
            %vertex
            obj.Plot = matlab.graphics.primitive.Surface(...
                'Parent',parent,...
                'PickableParts','none',...
                'HitTest','off',... %Mask is never clickable
                'Marker','none',...
                'MarkerSize',8,...
                'LineStyle','none',...
                'FaceColor','texturemap',...
                'FaceAlpha','texturemap',...
                'AlphaDataMapping','none',...
                'XData',[], ...
                'YData',[], ...
                'ZData',[], ...
                'CData',[],...
                'AlphaData',[],...
                'UserData',obj,...
                'EdgeColor','none');
            
            
        end %function
        
        
        function redrawOne(obj)
            
            % Calculate the data to update the plot
            [x,y,z,c,a] = obj.getPlotData();
            
            % Update the plot
            obj.Plot.XData = x;
            obj.Plot.YData = y;
            obj.Plot.ZData = z;
            obj.Plot.CData = c;
            obj.Plot.AlphaData = a;
            obj.Plot.Visible = obj.IsVisible;
            
        end %function
        
        
        function [x,y,z,c,a] = getPlotData(obj)
            % Calculate the data to update the plot
            
            % If we're in a 2D view, the viewer may have set a filter to
            % indicate the data range of the given slice. Check for that
            % condition
            
            % Validate the slice range
            sliceDim = all(isfinite(obj.SliceRangeFilter),2);
            
            % Is there a slice dimension? We can't show a 3D mask, so
            % return empties if we don't have a slice to show
            if any(sliceDim) && ~isempty( obj.Mask )
                % There is a valid slice dimension
                
                % Get the position of the selected slice
                rfilt = obj.SliceRangeFilter;
                slicePosCenter = mean(rfilt, 2);
                slicePosFront = rfilt(sliceDim,1);
                
                % Get the slice indices
                [maskIndicesCell,maskIndices] = obj.getSliceIndex(slicePosCenter);
                
                % Get the position of the mask's slice
                [x,y,z,isTranspose] = obj.getSliceXYZ(maskIndices);
                
                % Place each mask at a different depth between the center
                % and front edge of the view. Otherwise it won't render
                % multiple masks in the same plane
                % (Fixes a bug that exists at least to R2021a)
                siblings = obj.Plot.Parent.Children;
                childNum = find(siblings == obj.Plot(1));
                numSiblings = numel(siblings);
                adjustment = (childNum - 1) / numSiblings * ...
                    (slicePosCenter(sliceDim) - slicePosFront);
                slicePosFront = slicePosFront + adjustment;
                
                % Adjust the position of the annotations in the slice
                % dimension to move to the closer pixel edge. This way it
                % is renders in front of the imagery.
                if sliceDim(3)
                    % XY View
                        z(:) = slicePosFront;
                elseif sliceDim(2)
                    % YZ View
                        x(:) = slicePosFront;
                else
                    % XZ View
                        y(:) = slicePosFront;
                end %if
                
                % Get the mask for this slice
                mask = squeeze( obj.Mask(maskIndicesCell{:}) );
                if isTranspose
                    mask = mask';
                end
                
            else
                % There is not a valid slice dimension
                mask = [];
                x = [];
                y = [];
                z = [];
                
            end %if any(sliceDim)
            
            % Color data is not really used. Just make a matrix of ones.
            c = ones([size(mask) 3]);
            c(:,:,1) = obj.Color(1);
            c(:,:,2) = obj.Color(2);
            c(:,:,3) = obj.Color(3);
            
            % Prepare the alpha data
            a = mask * obj.Alpha;
            
        end %function
        
    end %methods
        
    
    
    %% Get/Set Methods
    methods
        
        function set.Mask(obj,value)
           obj.Mask = value;
           obj.DataSize = size(obj.Mask,[1 2 3]);
        end
    
    end %methods
    
end % classdef