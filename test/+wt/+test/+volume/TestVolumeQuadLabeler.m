classdef TestVolumeQuadLabeler < wt.test.volume.TestVolumeLabeler
    % Unit Test - Implements a unit test for a widget or component
    
    % Copyright 2020-2023 The MathWorks,Inc.
    
    
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

            % Dog dataset (Removed in R2023a)
            %dicomFolder = fullfile(matlabroot,"toolbox","images","imdata","dog");

            % Lung dataset
            zipFile = matlab.internal.examples.downloadSupportFile('medical','MedicalVolumeDICOMData.zip');
            parentFolder = fileparts(zipFile);
            unzip(zipFile, parentFolder)
            dicomFolder = fullfile(parentFolder,"MedicalVolumeDICOMData","LungCT01");

            % Load a different dataset
            fcn = @()wt.model.VolumeModel.fromDicomFile(dicomFolder);
            volModel = testCase.verifyWarningFree(fcn);

            % Assign the new dataset
            fcn = @()set(w,"VolumeModel",volModel);
            testCase.verifyWarningFree(fcn);
            
            % Verify each view changed
            testCase.verifyEqual(w.VolumeModel, volModel)
            testCase.verifyEqual(w.SliceView.VolumeModel, volModel)
            testCase.verifyEqual(w.TopView.VolumeModel, volModel)
            testCase.verifyEqual(w.SideView.VolumeModel, volModel)
  
        end %function
        
        
        
    end %methods(Test)
    
end %classdef