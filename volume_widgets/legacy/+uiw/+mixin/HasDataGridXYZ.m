classdef (Hidden, Abstract) HasDataGridXYZ < handle
    % HasDataGridXYZ - mixin class for models that contain XData, YData,
    % ZData grids
    %
    %
    % Notes:
    %
    %
    
    % Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: nhowes $
    %   $Revision: 322 $  $Date: 2018-10-16 14:25:23 -0400 (Tue, 16 Oct 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (AbortSet, SetObservable)
        XData (1,:) double {mustBeFinite} %X data range: empty or [xmin xmax]
        YData (1,:) double {mustBeFinite} %Y data range: empty or [ymin ymax]
        ZData (1,:) double {mustBeFinite} %Z data range: empty or [zmin zmax]
    end %properties
    
    properties (Transient, SetAccess=private)
        DataRange(3,2) double %Indicates the range of the data in all dimensions
        VoxelSize (1,3) double = [1 1 1] %Indicates the size of one voxel, based on X,Y,ZData and DataSize
    end %properties
    
    
    %% Abstract Properties
    properties (Abstract, SetAccess=protected)
        DataSize %Size of the Image, Mask, etc. that's being displayed
    end %properties
    
    
    %% Public Methods
    methods
        
        function [x,y,z,isTranspose] = getSliceXYZ(obj,sliceIdx)
            % Return the coordinates of the slice, presented in the format
            % [nan nan sliceNo]. The non-NaN position indicates the viewing
            % dimension for the 2D view.
            
            sliceIdx = double(sliceIdx);
            viewDim = ~isnan(sliceIdx);
            sliceNum = sliceIdx(viewDim);
            
            if all(viewDim == [0 0 1]) % XY view with slices in Z-dimension
                    x = obj.DataRange(2,:);
                    y = obj.DataRange(1,:);
                    z = obj.DataRange(3,1) + obj.VoxelSize(3) * (sliceNum - 0.5);
                    z = [z z; z z];
                    isTranspose = false;
            elseif all(viewDim == [0 1 0]) % YZ view with slices in X-dimension
                    
                    x = obj.DataRange(2,1) + obj.VoxelSize(2) * (sliceNum - 0.5);
                    x = [x x];
                    y = obj.DataRange(1,:);
                    z = [obj.DataRange(3,:); obj.DataRange(3,:)];
                    isTranspose = false;
            elseif all(viewDim == [1 0 0]) % XZ view with slices in Y-dimension
                    x = obj.DataRange(2,:);
                    y = obj.DataRange(1,1) + obj.VoxelSize(1) * (sliceNum - 0.5);
                    y = [y y];
                    z = [obj.DataRange(3,:); obj.DataRange(3,:)]';
                    isTranspose = true;
            else
                    error('HasDataGridXYZ:InvalidSliceDimension',...
                        'Invalid sliceDim specified');
                    
            end %switch
            
        end %function
        
        
        function range = getSliceRange(obj,sliceDim,sliceIdx)
            % Returns the range of a specified slice in data units
            
            range = obj.DataRange(sliceDim,1) + ...
                obj.VoxelSize(sliceDim) .* double([sliceIdx-1 sliceIdx]);
            
        end %function
        
        
        function indices = getSliceIndex(obj,slicePos)
            % Determine what slice indices the given position is in
            
            % What range is valid?
            dataRange = obj.DataRange;
            validRange = dataRange + obj.VoxelSize' * [-.5 .5]; %buffer
            
            % What is in range?
            inRange = slicePos(:) >= validRange(:,1) & slicePos(:) <= validRange(:,2);
            
            % Set default, then look at each dimension
            indices = {[],[],[]};
            
            vs = obj.VoxelSize;
            for idx = 1:3
                if inRange(idx)
                    sliceDiv = dataRange(idx,1):vs(idx):dataRange(idx,2);
                    thisIndex = find(slicePos(idx) <= sliceDiv, 1, 'first') - 1;
                    thisIndex = max(thisIndex,1);
                    indices{idx} = thisIndex;
                elseif isnan(slicePos(idx))
                    indices{idx} = ':';
                end
            end %for
            
        end %function
        
    end %methods
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function onDataGridChanged(obj)
            % Computes the DataRange and VoxelSize
            
            % What is the data size?
            sz = obj.DataSize;
            
            % Calculate the default data range by voxels
            obj.DataRange = [0 0 0; sz]' + 0.5;

            % If actual ranges were specified, calculate them instead
            if ~isempty(obj.YData)
                obj.DataRange(1,:) = obj.YData;
            end
            if ~isempty(obj.XData)
                obj.DataRange(2,:) = obj.XData;
            end
            if ~isempty(obj.ZData)
                obj.DataRange(3,:) = obj.ZData;
            end
            
            % Calculate voxel size
            obj.VoxelSize = diff(obj.DataRange,1,2)' ./ sz;
            
        end %function
        
    end %methods
    
    
    %% Get/Set Methods
    methods
        
        function set.XData(obj,value)
            if ~isempty(value)
                validateattributes(value,{'numeric'},{'finite','increasing','numel',2})
            end
            obj.XData = value;
            obj.onDataGridChanged();
        end
        
        function set.YData(obj,value)
            if ~isempty(value)
                validateattributes(value,{'numeric'},{'finite','increasing','numel',2})
            end
            obj.YData = value;
            obj.onDataGridChanged();
        end
        
        function set.ZData(obj,value)
            if ~isempty(value)
                validateattributes(value,{'numeric'},{'finite','increasing','numel',2})
            end
            obj.ZData = value;
            obj.onDataGridChanged();
        end
        
    end %methods
    
end % classdef