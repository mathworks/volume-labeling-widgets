classdef BaseIsosurfaceTest < wt.test.volume.BaseViewerTest
    % Unit Test - Implements a unit test for a widget or component
    
    % Copyright 2020 The MathWorks,Inc.
    
    
    %% Properties
    properties
        IsosurfaceModel (1,1) wt.model.IsosurfaceModel
    end
    
    %% Test Class Setup / Teardown
    methods (TestClassSetup)
        
        function importImagery(testCase)
            
            % Import a dataset
            s = load('mri.mat');
            data = squeeze(s.D);
            
            % Create isosurface
            isovalue = 40;
            [faces, vertices] = isosurface(data, isovalue);
            voxel_size  = [1 1 3];
            vertices    = vertices .* voxel_size;
            vertexNormals = isonormals(data,vertices);
            
            % Place into an IsosurfaceModel
            testCase.IsosurfaceModel = wt.model.IsosurfaceModel(...
                'Faces',faces,...
                'Vertices',vertices,...
                'VertexNormals',vertexNormals);
            
        end %function
        
    end %methods (TestClassSetup)
    
    
end %classdef