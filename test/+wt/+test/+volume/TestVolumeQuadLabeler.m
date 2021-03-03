classdef TestVolumeQuadLabeler < wt.test.volume.TestVolumeLabeler
    % Unit Test - Implements a unit test for a widget or component
    
    % Copyright 2020 The MathWorks,Inc.
    
    
    %% Helper Methods
    methods (Access = protected)
        
        function w = createAnnotationViewer(testCase)
            
            w = wt.VolumeQuadLabeler(...
                'Parent',testCase.Parent,...
                'VolumeModel',testCase.VolumeModel,...
                'View',"xy");
            
        end %function
        
    end %methods
    
    
    
    
    %% Test Methods
    methods(Test)
        
        %% Test Default Construction
        function testDefaultConstructor(testCase)
            
            fcn = @()wt.VolumeQuadLabeler();
            w = testCase.verifyWarningFree(fcn);
            
            % Clean up figure
            delete(w.Parent);
            
        end %function
        
        
        %% Test changing dataset
        function testChangingDataset(testCase)
            
            w = testCase.createAnnotationViewer();

            % Load a different dataset
            dicomFolder = fullfile(matlabroot,"toolbox","images","imdata","dog");
            fcn = @()wt.model.VolumeModel.fromDicomFile(dicomFolder);
            %dogModel = testCase.verifyWarning(fcn, 'VolumeModel:fromDicom:NonUniformZ', "Expected a warning");
            %dogModel = wt.model.VolumeModel.fromDicomFile(dicomFolder);
            dogModel = testCase.verifyWarningFree(fcn);

            % Assign the new dataset
            fcn = @()set(w,"VolumeModel",dogModel);
            testCase.verifyWarningFree(fcn);
            
            % Verify each view changed
            testCase.verifyEqual(w.VolumeModel, dogModel)
            testCase.verifyEqual(w.SliceView.VolumeModel, dogModel)
            testCase.verifyEqual(w.TopView.VolumeModel, dogModel)
            testCase.verifyEqual(w.SideView.VolumeModel, dogModel)
  
        end %function
        
        
        
    end %methods(Test)
    
end %classdef