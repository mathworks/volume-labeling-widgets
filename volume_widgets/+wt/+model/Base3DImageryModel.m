classdef (Abstract) Base3DImageryModel < handle
    % Mixin class for models that contain 3D imagery
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    
    %% Read-Only Properties
    properties (SetAccess = protected)
        
        % Size of the Image, Mask, etc. that's being displayed (subclass
        % must set)
        DataSize (3,1) double = zeros(3,1);
        
    end %properties
    
    
    
    %% Properties
    properties (AbortSet, SetObservable)
        
        % World coordinate range in [Ymin,Xmin,Zmin; Ymax,Xmax,Zmax], referenced to the outermost edges of the pixels
        WorldExtent (3,2) double = [zeros(3,1), ones(3,1)]
        
    end %properties
    
    
    
    %% Read-Only Properties
    properties (SetAccess = private)
        
        % World coordinate range in [Ymin,Xmin,Zmin; Ymax,Xmax,Zmax], referenced to the centers of the first and last pixels
        WorldExtentPixelCenters (3,2) double = [zeros(3,1), ones(3,1)]
        
        % Indicates the size of one voxel, based on X,Y,ZData and DataSize
        PixelExtent (3,1) double = inf(3,1)
        
        % Pixel Edges Grid (Y,X,Z)
        PixelEdges (3,1) cell = repmat({[0 1]},3,1)
        
        % Pixel Centers Grid (Y,X,Z)
        PixelCenters (3,1) cell = repmat({0.5},3,1)
        
    end %properties
    
    
    
    %% Public Methods
    methods
        
        function [x,y,z,isTranspose] = getSliceXYZ(obj,sliceIdx)
            % Return the coordinates of the slice, where slice is provided
            % in the format [nan nan sliceNo]. The non-NaN position
            % indicates the viewing dimension for the 2D view. The returned
            % values are the coordinates of the slice given the outer edges
            % of the pixel coordinates for display on a texturemap surface
            % plot.
            
            % Which dimension and slice are requested?
            sliceIdx = double(sliceIdx);
            viewDim = ~isnan(sliceIdx);
            isTranspose = false;
            
            % Which view are we looking at?
            if all(viewDim == [0 0 1])
                % XY view with slices in Z-dimension
                
                % The slice by pixel edges
                y = obj.WorldExtent(1,:);
                x = obj.WorldExtent(2,:);
                
                % The coordinates of the slice - to pixel center
                z(1:2,1:2) = obj.PixelCenters{3}(sliceIdx(3));
                
            elseif all(viewDim == [0 1 0])
                % YZ view with slices in X-dimension
                
                % The slice by pixel edges
                y = obj.WorldExtent(1,:);
                z = [obj.WorldExtent(3,:); obj.WorldExtent(3,:)];
                
                % The coordinates of the slice - to pixel center
                x(1:2) = obj.PixelCenters{2}(sliceIdx(2));
                
            elseif all(viewDim == [1 0 0])
                % XZ view with slices in Y-dimension
                
                % The slice by pixel edges
                x = obj.WorldExtent(2,:);
                z = [obj.WorldExtent(3,:); obj.WorldExtent(3,:)]'; %transposed
                
                % The coordinates of the slice - to pixel center
                y(1:2) = obj.PixelCenters{1}(sliceIdx(1));
                
                % This view is transpoosed in display
                isTranspose = true;
                
            else
                error('HasDataGridXYZ:InvalidSliceDimension',...
                    'Invalid sliceDim specified');
                
            end %switch
            
            
        end %function
        
        
        function [range,range3D] = getSliceRange(obj,sliceDim,sliceIdx)
            % Returns the world extents along the thickness of a specified slice
            
            range = obj.PixelEdges{sliceDim}([sliceIdx sliceIdx+1]);
            range3D = inf(3,2) .* [-1 1];
            range3D(sliceDim,:) = range;
            
        end %function
        
        
        function [indicesCell,indices] = getSliceIndex(obj,slicePos)
            % Find the slice indices for a given world coordinate
            
            % Set default, then look at each dimension
            indices = nan(1,3);
            indicesCell = {':',':',':'};
            
            for idx = 1:3
                if ~isnan(slicePos(idx))
                    indicesCell{idx} = find(slicePos(idx) <= obj.PixelEdges{idx}, 1, 'first') - 1;
                    if isempty(indicesCell{idx})
                        indicesCell{idx} = obj.DataSize(idx);
                    elseif indicesCell{idx} < 1
                        indicesCell{idx} = 1;
                    end
                    indices(idx) = indicesCell{idx};
                end
            end %for
            
        end %function
        
        
        function [X,Y,Z] = voxelcenters( obj )
            %voxelcenters Return voxel centers
            
            disp('Replace with PixelCenters');
            
            Y = obj.WorldExtentPixelCenters(1,1) : obj.PixelExtent(1) : obj.WorldExtentPixelCenters(1,2);
            X = obj.WorldExtentPixelCenters(2,1) : obj.PixelExtent(2) : obj.WorldExtentPixelCenters(2,2);
            Z = obj.WorldExtentPixelCenters(3,1) : obj.PixelExtent(3) : obj.WorldExtentPixelCenters(3,2);
            
        end %function
        
    end %methods
    
    
    %% Private methods
    methods (Access = private)
        
        function calculateGrid(obj)
            % calculate the grids for calculations
            
            % Pixel size
            obj.PixelExtent = diff(obj.WorldExtent,[],2) ./ obj.DataSize;
            
            % Pixel edges
            obj.PixelEdges = {
                obj.WorldExtent(1,1) : obj.PixelExtent(1) : obj.WorldExtent(1,2)
                obj.WorldExtent(2,1) : obj.PixelExtent(2) : obj.WorldExtent(2,2)
                obj.WorldExtent(3,1) : obj.PixelExtent(3) : obj.WorldExtent(3,2)
                }';
            
            % World extent by pixel centers
            obj.WorldExtentPixelCenters = obj.WorldExtent + (obj.PixelExtent .* [0.5 -0.5]);
            
            % Pixel centers
            obj.PixelCenters = {
                obj.WorldExtentPixelCenters(1,1) : obj.PixelExtent(1) : obj.WorldExtentPixelCenters(1,2)
                obj.WorldExtentPixelCenters(2,1) : obj.PixelExtent(2) : obj.WorldExtentPixelCenters(2,2)
                obj.WorldExtentPixelCenters(3,1) : obj.PixelExtent(3) : obj.WorldExtentPixelCenters(3,2)
                }';
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        function set.DataSize(obj,value)
            obj.DataSize = value;
            obj.calculateGrid();
        end
        
        function set.WorldExtent(obj,value)
            obj.WorldExtent = value;
            obj.calculateGrid();
        end
        
    end %methods
    
end % classdef