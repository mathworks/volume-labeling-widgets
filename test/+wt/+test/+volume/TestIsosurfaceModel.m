classdef TestIsosurfaceModel < matlab.unittest.TestCase
    % Implements a unit test for a widget or component
    
    % Copyright 2018-2020 The MathWorks,Inc.
    
    %% Properties
    properties
        ImageData
        IsosurfaceData
    end
    
    %% Test Class Setup / Teardown
    methods (TestClassSetup)
        
        function importImagery(testCase)
            
            % Import a dataset
            s = load('mri.mat');
            testCase.ImageData = squeeze(s.D);
            
            % Create isosurface
            isovalue = 40;
            [faces, vertices] = isosurface(testCase.ImageData, isovalue);
            voxel_size  = [1 1 3];
            vertices    = vertices .* voxel_size;
            vertexNormals = isonormals(testCase.ImageData, vertices);
            
            testCase.IsosurfaceData.Faces = faces;
            testCase.IsosurfaceData.Vertices = vertices .* voxel_size;
            testCase.IsosurfaceData.VertexNormals = vertexNormals;
            
        end %function
        
    end %methods (TestClassSetup)
    
    
    %% Test Methods
    methods(Test)
        
        %% Test Default Construction
        function testDefaultConstructor(testCase)
            
            fcn = @()wt.model.IsosurfaceModel();
            testCase.verifyWarningFree(fcn)
            
        end %function
        
        
        %% Test Construction with Data
        function testConstruction(testCase)
            
            fcn = @()wt.model.IsosurfaceModel(...
                'Faces',testCase.IsosurfaceData.Faces,...
                'Vertices',testCase.IsosurfaceData.Vertices,...
                'VertexNormals',testCase.IsosurfaceData.VertexNormals);
            testCase.verifyWarningFree(fcn)
            
        end %function
        
    end %methods(Test)
    
end %classdef