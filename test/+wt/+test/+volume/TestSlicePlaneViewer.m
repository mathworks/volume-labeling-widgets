classdef TestSlicePlaneViewer < wt.test.volume.BaseViewerTest & ...
        wt.test.volume.BaseVolumeTest
    % Unit Test - Implements a unit test for a widget or component
    
    % Copyright 2020 The MathWorks,Inc.
    
    
    %% Test Methods
    methods(Test)
        
        %% Test Default Construction
        function testDefaultConstructor(testCase)
            
            fcn = @()wt.SlicePlaneViewer();
            w = testCase.verifyWarningFree(fcn);
            
            % Clean up figure
            delete(w.Parent);
            
        end %function
        
        
        %% Test Construction with Data
        function testConstruction(testCase)
            
            fcn = @()wt.SlicePlaneViewer('VolumeModel',testCase.VolumeModel);
            w = testCase.verifyWarningFree(fcn);
            
            % Clean up figure
            delete(w.Parent);
            
        end %function
        
        
        %% Test Construction with Inputs
        function testConstructionArguments(testCase)
            
            fcn = @()wt.SlicePlaneViewer(...
                'Parent',testCase.Parent,...
                'VolumeModel',testCase.VolumeModel,...
                'Slice',[3 5 10],...
                'BackgroundColor',[0.5 0.5 0.5],...
                'Visible','on');
            
            testCase.verifyWarningFree(fcn)
            
        end %function
        
        
        
        %% Test if order of inputs matters
        function testOrderOfInputs(testCase)
            
            w = wt.SlicePlaneViewer(...
                'Parent',testCase.Parent,...
                'VolumeModel',testCase.VolumeModel,...
                'Slice',[100 19 20]);
            
            testCase.verifyEqual(w.Slice, double([100 19 20]))
            
            w = wt.SlicePlaneViewer(...
                'Parent',testCase.Parent,...
                'Slice',[100 19 20],...
                'VolumeModel',testCase.VolumeModel);
            
            testCase.verifyEqual(w.Slice, double([100 19 20]))
            
        end %function
        
        
        
        %% Test ok values
        function testOkValues(testCase)
            
            w = wt.SlicePlaneViewer(...
                'Parent',testCase.Parent,...
                'VolumeModel',testCase.VolumeModel,...
                'Slice',[100 19 20]);
            
            % Set an valid slice
            w.Slice = [10 23 2];
            testCase.verifyEqual(w.Slice,double([10 23 2]));
            
            numSlice = testCase.VolumeModel.DataSize;
            w.Slice = numSlice;
            testCase.verifyEqual(w.Slice,double(numSlice'));
            
        end %function
        
        
        
        %% Test incorrect values that throw an error
        function testBadValues(testCase)
            
            w = wt.SlicePlaneViewer(...
                'Parent',testCase.Parent,...
                'VolumeModel',testCase.VolumeModel,...
                'Slice',[1 2 3]);
            
            % Set an invalid slice
            w.Slice = [1000 23 2];
            testCase.verifyNotEqual(w.Slice,double([1000 23 2]));
            
            % Set an valid slice
            w.Slice = [4 5 6];
            testCase.verifyEqual(w.Slice,double([4 5 6]));
            
            % Set an invalid slice
            w.Slice = 3;
            testCase.verifyEqual(w.Slice,double([3 3 3]));
            
        end %function
        
        
        %% Test use of X/Y/Z dimensions
        function testPositionData(testCase)
            
            w = wt.SlicePlaneViewer(...
                'Parent',testCase.Parent,...
                'VolumeModel',testCase.VolumeModel);
            
            % Change slice
            w.Slice = [4 5 6];
            testCase.verifyEqual(w.Slice, double([4 5 6]))
            
        end %function
        
    end %methods(Test)
    
end %classdef