classdef BaseVolumeTest < matlab.unittest.TestCase
    % Unit Test - Implements a unit test for a widget or component
    
    % Copyright 2020 The MathWorks,Inc.
    
    
    %% Properties
    properties
        ImageData
        VolumeModel (1,1) wt.model.VolumeModel
    end
    
    %% Test Class Setup / Teardown
    methods (TestClassSetup)
        
        function importImagery(testCase)
            
            % Import a dataset
            s = load('mristack.mat');
            testCase.ImageData = s.mristack;
            
        end %function
        
    end %methods (TestClassSetup)
    
    
    %% Test Method Setup / Teardown
    methods (TestMethodSetup)
    
        function createVolumeModel(testCase)
            
            testCase.VolumeModel = wt.model.VolumeModel('ImageData',testCase.ImageData);
            testCase.VolumeModel.WorldExtent = [
                5 2565% Y dimension
                5 2565% X dimension
                5 215 % Z dimension
                ];
            
        end %function
    
    end %methods (TestMethodSetup)
    
    
end %classdef