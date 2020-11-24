classdef TestVolumeModel < wt.test.volume.BaseVolumeTest
    % Unit Test - Implements a unit test for a widget or component
    
    % Copyright 2018-2020 The MathWorks,Inc.
    
   
    
    %% Test Methods
    methods(Test)
        
        %% Test Default Construction
        function testDefaultConstructor(testCase)
            
            fcn = @()wt.model.VolumeModel();
            testCase.verifyWarningFree(fcn)
            
        end %function
        
        
        %% Test Construction with Data
        function testConstruction(testCase)
            
            fcn = @()wt.model.VolumeModel('ImageData',testCase.ImageData);
            testCase.verifyWarningFree(fcn)
            
        end %function
        
        
        
        %% Test DataGrid positioning and sizing properties
        function testDataGridProperties(testCase)
            
            % Indicate the distances for each axis to set voxel sizes
            testCase.VolumeModel.WorldExtent = [
                0 11 % Y dimension
                0 10 % X dimension
                0 12 % Z dimension
                ];
            
            % Data size
            expValue = [256 256 21]';
            testCase.verifyEqual(testCase.VolumeModel.DataSize, expValue)
            
            
            % Positional range
            expValue = [
                0 11
                0 10
                0 12
                ];
            testCase.verifyEqual(testCase.VolumeModel.WorldExtent, expValue)
            
            expValue = diff(testCase.VolumeModel.WorldExtent,[],2) ./ testCase.VolumeModel.DataSize;
            testCase.verifyEqual(testCase.VolumeModel.PixelExtent, expValue,...
                'RelTol',0.001,'AbsTol',0.001)
            
        end %function
        
        
        %% Test DataGrid positioning and sizing methods
        function testGetSliceXYZ(testCase)
            
            % XY View
            sliceIdx = [nan nan 3];
            [x,y,z,isTranspose] = testCase.VolumeModel.getSliceXYZ(sliceIdx);
            
            expValue = testCase.VolumeModel.WorldExtent(2,:);
            testCase.verifyEqual(x, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            expValue = testCase.VolumeModel.WorldExtent(1,:);
            testCase.verifyEqual(y, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            expValue = [30 30; 30 30];
            testCase.verifyEqual(z, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            expValue = false;
            testCase.verifyEqual(isTranspose, expValue)
            
            
            % YZ View
            sliceIdx = [nan 15 nan];
            [x,y,z,isTranspose] = testCase.VolumeModel.getSliceXYZ(sliceIdx);
            
            expValue = [150 150];
            testCase.verifyEqual(x, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            expValue = testCase.VolumeModel.WorldExtent(1,:);
            testCase.verifyEqual(y, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            expValue = repmat(testCase.VolumeModel.WorldExtent(3,:),2,1);
            testCase.verifyEqual(z, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            expValue = false;
            testCase.verifyEqual(isTranspose, expValue)
            
            
            % XZ View
            sliceIdx = [7 nan nan];
            [x,y,z,isTranspose] = testCase.VolumeModel.getSliceXYZ(sliceIdx);
            
            expValue = testCase.VolumeModel.WorldExtent(2,:);
            testCase.verifyEqual(x, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            expValue = [70 70];
            testCase.verifyEqual(y, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            expValue = repmat(testCase.VolumeModel.WorldExtent(3,:),2,1)';
            testCase.verifyEqual(z, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            expValue = true;
            testCase.verifyEqual(isTranspose, expValue)
            
            
            % Incorrect View
            sliceIdx = [7 1 nan];
            fcn = @()testCase.VolumeModel.getSliceXYZ(sliceIdx);
            testCase.verifyError(fcn,'HasDataGridXYZ:InvalidSliceDimension');
            
            
        end %function
        
        
        function testPixelEdges(testCase)
            
            expValue = 5:10:2565;
            testCase.verifyEqual(testCase.VolumeModel.PixelEdges{2}, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            expValue = 5:10:2565;
            testCase.verifyEqual(testCase.VolumeModel.PixelEdges{1}, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            expValue = 5:10:215;
            testCase.verifyEqual(testCase.VolumeModel.PixelEdges{3}, expValue,'RelTol',0.001,'AbsTol',0.001)
            
        end %function
        
        
        function testPixelCenters(testCase)
            
            expValue = 10:10:2560;
            testCase.verifyEqual(testCase.VolumeModel.PixelCenters{2}, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            expValue = 10:10:2560;
            testCase.verifyEqual(testCase.VolumeModel.PixelCenters{1}, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            expValue = 10:10:210;
            testCase.verifyEqual(testCase.VolumeModel.PixelCenters{3}, expValue,'RelTol',0.001,'AbsTol',0.001)
            
        end %function
        
        
        function testGetSliceRange(testCase)
            
            % XY View
            sliceIdx = 4;
            sliceDim = 3;
            range = testCase.VolumeModel.getSliceRange(sliceDim,sliceIdx);
            
            expValue = [35    45];
            testCase.verifyEqual(range, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            % YZ View
            sliceIdx = 7;
            sliceDim = 2;
            range = testCase.VolumeModel.getSliceRange(sliceDim,sliceIdx);
            
            expValue = [65    75];
            testCase.verifyEqual(range, expValue,'RelTol',0.001,'AbsTol',0.001)
            
            % XZ View
            sliceIdx = 19;
            sliceDim = 1;
            range = testCase.VolumeModel.getSliceRange(sliceDim,sliceIdx);
            
            expValue = [185   195];
            testCase.verifyEqual(range, expValue,'RelTol',0.001,'AbsTol',0.001)
            
        end %function
        
        
        function testGetSliceIndex(testCase)
            
            % XY View
            expValue = {':',':',4};
            
            % middle of slice
            slicePos = [nan nan 40];
            indices = testCase.VolumeModel.getSliceIndex(slicePos);
            testCase.verifyEqual(indices, expValue)
            
            % near ends of slice
            slicePos = [nan nan 36];
            indices = testCase.VolumeModel.getSliceIndex(slicePos);
            testCase.verifyEqual(indices, expValue)
            
            slicePos = [nan nan 44];
            indices = testCase.VolumeModel.getSliceIndex(slicePos);
            testCase.verifyEqual(indices, expValue)
            
            
            % YZ View
            expValue = {':',6,':'};
            
            % middle of slice
            slicePos = [nan 60 nan];
            indices = testCase.VolumeModel.getSliceIndex(slicePos);
            testCase.verifyEqual(indices, expValue)
            
            % near ends of slice
            slicePos = [nan 64 nan];
            indices = testCase.VolumeModel.getSliceIndex(slicePos);
            testCase.verifyEqual(indices, expValue)
            
            slicePos = [nan 56 nan];
            indices = testCase.VolumeModel.getSliceIndex(slicePos);
            testCase.verifyEqual(indices, expValue)
            
            
            % XZ View
            expValue = {19,':',':'};
            
            % middle of slice
            slicePos = [190 nan nan];
            indices = testCase.VolumeModel.getSliceIndex(slicePos);
            testCase.verifyEqual(indices, expValue)
            
            % near ends of slice
            slicePos = [186 nan nan];
            indices = testCase.VolumeModel.getSliceIndex(slicePos);
            testCase.verifyEqual(indices, expValue)
            
            slicePos = [194 nan nan];
            indices = testCase.VolumeModel.getSliceIndex(slicePos);
            testCase.verifyEqual(indices, expValue)
            
        end %function
        
    end %methods(Test)
    
end %classdef