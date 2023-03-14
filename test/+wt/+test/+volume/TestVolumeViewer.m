classdef TestVolumeViewer < wt.test.volume.BaseViewerTest & ...
        wt.test.volume.BaseVolumeTest
    % Unit Test - Implements a unit test for a widget or component
    
    % Copyright 2020 The MathWorks,Inc.
    
    %% Properties
    properties
        Viewer
    end
    
    
    %% Test Method Setup / Teardown
    methods(TestMethodSetup)
        
        function createViewer(testCase)
            
            % Create a viewer
            fcn = @()wt.VolumeViewer(testCase.Parent);
            testCase.Viewer = testCase.verifyWarningFree(fcn);
            
            % Attach a volume model
            testCase.Viewer.VolumeModel = testCase.VolumeModel;
            
            % Allow drawing to finish
            drawnow
            
        end %function
        
    end %methods(TestMethodSetup)
    
    
    
    %% Helper Methods
    methods (Access = protected)
        
        function assumeInitialConditions(testCase)
            % Verify slice controls in the viewer
            
            expectedSlice = 1;
            testCase.assumeEqual(testCase.Viewer.Slice, expectedSlice);
            testCase.assumeEqual(testCase.Viewer.SliceSpinner.Value, expectedSlice);
            testCase.assumeEqual(testCase.Viewer.SliceSlider.Value, expectedSlice);
            
            expectedSlice3D = [1 1 1];
            testCase.assumeEqual(testCase.Viewer.Slice3D, expectedSlice3D);
            
            expectedSliceDimension = logical([0 0 1]);
            testCase.assumeEqual(testCase.Viewer.SliceDimension, expectedSliceDimension);
            
            expectedView = wt.enum.ViewAxis.xy;
            testCase.assumeEqual(testCase.Viewer.ViewIndicator.Value, expectedView);
            testCase.assumeEqual(testCase.Viewer.View, expectedView);
            
        end %function
        
        
        function verifySlice(testCase, expectedValue)
            % Verify slice controls in the viewer
            
            % Ensure any updates complete
            drawnow
            pause(2)
            drawnow

            testCase.verifyEqual(testCase.Viewer.SliceSpinner.Value, expectedValue,'RelTol',0.001,'AbsTol',0.001);
            testCase.verifyEqual(testCase.Viewer.SliceSlider.Value, expectedValue,'RelTol',0.001,'AbsTol',0.001);
            testCase.verifyEqual(testCase.Viewer.Slice, expectedValue,'RelTol',0.001,'AbsTol',0.001);
            slice3DValue = testCase.Viewer.Slice3D(testCase.Viewer.SliceDimension);
            testCase.verifyEqual(slice3DValue, expectedValue,'RelTol',0.001,'AbsTol',0.001);
            
        end %function
        
        
        function assumeSlice(testCase, expectedValue)
            % Verify slice controls in the viewer
            
            drawnow
            testCase.assumeEqual(testCase.Viewer.SliceSpinner.Value, expectedValue);
            testCase.assumeEqual(testCase.Viewer.SliceSlider.Value, expectedValue);
            testCase.assumeEqual(testCase.Viewer.Slice, expectedValue);
            
        end %function
        
        
        function verifyView(testCase, expectedValue)
            % Verify view controls in the viewer
            
            if isstring(expectedValue)
                expectedValue = wt.enum.ViewAxis.(expectedValue);
            end
            
            drawnow
            testCase.verifyEqual(testCase.Viewer.ViewIndicator.Value, expectedValue);
            testCase.verifyEqual(testCase.Viewer.View, expectedValue);
            
            expectedSliceDimension = expectedValue == ["xz" "yz" "xy"];
            testCase.verifyEqual(testCase.Viewer.SliceDimension, expectedSliceDimension);
            
            
        end %function
        
        
        function assumeView(testCase, expectedValue)
            % Verify view controls in the viewer
            
            drawnow
            testCase.assumeEqual(testCase.Viewer.ViewIndicator.Value, expectedValue);
            testCase.assumeEqual(testCase.Viewer.View, expectedValue);
            
            expectedSliceDimension = expectedValue == ["xz" "yz" "xy"];
            testCase.assumeEqual(testCase.Viewer.SliceDimension, expectedSliceDimension);
            
        end %function
        
    end %methods
    
    
    
    %% Test Methods
    methods(Test)
        
        %% Defaults
        function testDefaults(testCase)
            
            expectedSlice = 1;
            testCase.verifyEqual(testCase.Viewer.Slice, expectedSlice);
            testCase.verifyEqual(testCase.Viewer.SliceSpinner.Value, expectedSlice);
            testCase.verifyEqual(testCase.Viewer.SliceSlider.Value, expectedSlice);
            
            expectedSlice3D = [1 1 1];
            testCase.verifyEqual(testCase.Viewer.Slice3D, expectedSlice3D);
            
            expectedSliceDimension = logical([0 0 1]);
            testCase.verifyEqual(testCase.Viewer.SliceDimension, expectedSliceDimension);
            
            expectedView = wt.enum.ViewAxis.xy;
            testCase.verifyEqual(testCase.Viewer.ViewIndicator.Value, expectedView);
            testCase.verifyEqual(testCase.Viewer.View, expectedView);
            
        end %function

        
        %% Slice Slider
        function testSlider(testCase)
            
            % Initial Conditions
            testCase.assumeInitialConditions();

            % Drag the slider
            testCase.drag(testCase.Viewer.SliceSlider, 4, 17)
            testCase.verifySlice(17);
            
            % Drag the slider
            testCase.drag(testCase.Viewer.SliceSlider, 17, 9)
            testCase.verifySlice(9);
            
            % Drag the slider to a fractional value
            testCase.drag(testCase.Viewer.SliceSlider, 13, 17.8)
            drawnow; pause(2); drawnow % Give it time to update
            testCase.verifySlice(18);
            
        end %function
        
        
        
        %% Slice Spinner
        function testSpinner(testCase)
            
            % Initial Conditions
            testCase.assumeInitialConditions();

            % Set initial slice
            testCase.Viewer.Slice = 10;
            testCase.verifySlice(10);
            
            % Move the spinner
            testCase.press(testCase.Viewer.SliceSpinner,'down')
            testCase.press(testCase.Viewer.SliceSpinner,'down')
            testCase.verifySlice(8);
            
            % Type in the spinner
            testCase.type(testCase.Viewer.SliceSpinner, 15)
            testCase.verifySlice(15);
            
            % Move the spinner
            testCase.press(testCase.Viewer.SliceSpinner,'up')
            testCase.press(testCase.Viewer.SliceSpinner,'up')
            testCase.press(testCase.Viewer.SliceSpinner,'up')
            testCase.verifySlice(18);
            
            % Type a fractional value
            testCase.type(testCase.Viewer.SliceSpinner, 7.8)
            testCase.verifySlice(8);
            
        end %function
        
        
        
        %% Slice Spinner Limits
        function testSpinnerLimits(testCase)
            
            % Initial Conditions
            testCase.assumeInitialConditions();
            
            % Move the spinner (past limits)
            testCase.press(testCase.Viewer.SliceSpinner,'down')
            testCase.press(testCase.Viewer.SliceSpinner,'down')
            testCase.press(testCase.Viewer.SliceSpinner,'down')
            testCase.press(testCase.Viewer.SliceSpinner,'down')
            testCase.verifySlice(1);
            
            % Type in the spinner (past limits)
            testCase.type(testCase.Viewer.SliceSpinner, 12345)
            testCase.verifySlice(1);
            
            % Wait for error to clear
            pause(2)
            
            % Move the spinner
            testCase.press(testCase.Viewer.SliceSpinner,'up')
            testCase.verifySlice(2);
            
            % Move the spinner
            testCase.press(testCase.Viewer.SliceSpinner,'up')
            testCase.press(testCase.Viewer.SliceSpinner,'up')
            testCase.press(testCase.Viewer.SliceSpinner,'up')
            testCase.verifySlice(5);
            
            % Type in the spinner (past limits)
            testCase.type(testCase.Viewer.SliceSpinner, -5)
            testCase.verifySlice(5);
            
        end %function
        
        
        
        %% Change Slice Programmatically
        function testSlice(testCase)
            
            % Initial Conditions
            testCase.assumeInitialConditions();
            
            % Change slice
            testCase.Viewer.Slice = 15;
            testCase.verifySlice(15);
            
        end %function
        
        
        
        %% Change to an Invalid Slice
        function testSliceInvalid(testCase)
            
            % Initial Conditions
            testCase.assumeInitialConditions();
            
            % Change slice
            testCase.Viewer.Slice = 15;
            testCase.verifySlice(15);
            
        end %function
        
        
        
        %% View Dropdown
        function testViewDropdown(testCase)
            
            % Initial Conditions
            testCase.assumeInitialConditions();

            % Select a view
            testCase.choose(testCase.Viewer.ViewIndicator,"XZ")
            testCase.verifyView("xz");
            testCase.verifyEqual(testCase.Viewer.SliceDimension, logical([1 0 0]));

            % Select a view
            testCase.choose(testCase.Viewer.ViewIndicator,"YZ")
            testCase.verifyView("yz");
            testCase.verifyEqual(testCase.Viewer.SliceDimension, logical([0 1 0]));

            % Select a view
            testCase.choose(testCase.Viewer.ViewIndicator,"XY")
            testCase.verifyView("xy");
            testCase.verifyEqual(testCase.Viewer.SliceDimension, logical([0 0 1]));
            
        end %function
        
        
        
        %% Change View Programmatically
        function testView(testCase)
            
            % Initial Conditions
            testCase.assumeInitialConditions();
            
            % Select a view
            testCase.Viewer.View = "xz";
            testCase.verifyView("xz");
            testCase.verifyEqual(testCase.Viewer.SliceDimension, logical([1 0 0]));

            % Select a view
            testCase.Viewer.View = "yz";
            testCase.verifyView("yz");
            testCase.verifyEqual(testCase.Viewer.SliceDimension, logical([0 1 0]));

            % Select a view
            testCase.Viewer.View = "xy";
            testCase.verifyView("xy");
            testCase.verifyEqual(testCase.Viewer.SliceDimension, logical([0 0 1]));
            
        end %function
        
        
        %% Slice depends on view
        function testSliceDependsOnView(testCase)
            
            % Initial Conditions
            testCase.assumeInitialConditions();
            
            % Change slice
            newSlice3D = [136,76,21];
            testCase.Viewer.Slice3D = newSlice3D;
            testCase.verifySlice(21);
            testCase.verifyEqual(testCase.Viewer.Slice3D, newSlice3D);
            
            % Select a view
            testCase.Viewer.View = "xz";
            testCase.verifyView("xz");
            testCase.verifySlice(136);

            % Select a view
            testCase.Viewer.View = "yz";
            testCase.verifyView("yz");
            testCase.verifySlice(76);

            % Select a view
            testCase.Viewer.View = "xy";
            testCase.verifyView("xy");
            testCase.verifySlice(21);
            
        end %function
        
        
        
%         %% Test incorrect values that throw an error
%         function testBadValues(testCase)
%             
% %             testCase.Viewer = wt.VolumeViewer(...
% %                 'Parent',testCase.Parent,...
% %                 'VolumeModel',testCase.VolumeModel,...
% %                 'View',"xy",...
% %                 'Slice',13);
%             
%             % Check view
%             testCase.assumeEqual(testCase.Viewer.View, "xy")
%             
%             % Set an invalid slice
%             testCase.Viewer.Slice = 1000;
%             testCase.verifyNotEqual(testCase.Viewer.Slice,double(1000));
%             
%             % Set an invalid view
%             fcn = @() set(testCase.Viewer,'View','not a view');
%             verifyError(testCase, fcn, 'MATLAB:validators:mustBeMember');
%             
%             % Set an invalid slice
%             numSlice = testCase.VolumeModel.DataSize(3);
%             testCase.Viewer.Slice = numSlice;
%             testCase.verifyEqual(testCase.Viewer.Slice,double(numSlice));
%             
%             % Set an invalid view
%             fcn = @() set(testCase.Viewer,'View','not a view');
%             verifyError(testCase, fcn, 'MATLAB:validators:mustBeMember');
%             
%         end %function
%         
%         
%         %% Test different view
%         function testSideView(testCase)
%             
% %             testCase.Viewer = wt.VolumeViewer(...
% %                 'Parent',testCase.Parent,...
% %                 'VolumeModel',testCase.VolumeModel,...
% %                 'View',"yz",...
% %                 'Slice',13);
% %             drawnow
%             
%             testCase.verifyEqual(testCase.Viewer.View, "yz")
%             testCase.verifyEqual(testCase.Viewer.Slice, double(13))
%             
%             testCase.Viewer.View = "xz";
%             drawnow
%             testCase.verifyEqual(testCase.Viewer.View, "xz")
%             
%         end %function
%         
%         
%         %% Test view options
%         function testViewOptions(testCase)
%             
% %             testCase.Viewer = wt.VolumeViewer(...
% %                 'Parent',testCase.Parent,...
% %                 'Slice',13,...
% %                 'VolumeModel',testCase.VolumeModel,...
% %                 'View',"yz");
%             
%             % Turn on optional axes and grid
%             testCase.Viewer.ShowAxes = true;
%             testCase.Viewer.ShowGrid = true;
%             
%         end %function
%         
%         
%         %% Test use of X/Y/Z dimensions
%         function testPositionData(testCase)
%             
%             % Indicate the distances for each axis to set voxel sizes
%             testCase.VolumeModel.XData = [0 10];
%             testCase.VolumeModel.YData = [0 10];
%             testCase.VolumeModel.ZData = [0 10];
%             
%             % Change slice
%             testCase.Viewer.Slice = 17;
%             
%             testCase.verifyEqual(testCase.Viewer.View, "xy")
%             testCase.verifyEqual(testCase.Viewer.Slice, double(17))
%             
%         end %function
        
    end %methods(Test)
    
end %classdef