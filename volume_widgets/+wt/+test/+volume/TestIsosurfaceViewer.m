classdef TestIsosurfaceViewer < wt.test.volume.BaseIsosurfaceTest
    % Unit Test - Implements a unit test for a widget or component
    
    % Copyright 2018-2019 The MathWorks,Inc.

    
    %% Test Methods
    methods(Test)
        
        %% Test Default Construction
        function testDefaultConstructor(testCase)
            
            fcn = @()wt.IsosurfaceViewer();
            w = testCase.verifyWarningFree(fcn);
            
            % Clean up figure
            delete(w.Parent);
            
        end %function
        
        
        %% Test Construction with Data
        function testConstruction(testCase)
            
            fcn = @()wt.IsosurfaceViewer('IsosurfaceModel',testCase.IsosurfaceModel);
            w = testCase.verifyWarningFree(fcn);
            
            % Clean up figure
            delete(w.Parent);
            
        end %function
        
        
        %% Test Construction with Inputs
        function testConstructionArguments(testCase)
            
            fcn = @()wt.IsosurfaceViewer(...
                'Parent',testCase.Parent,...
                'IsosurfaceModel',testCase.IsosurfaceModel,...
                'BackgroundColor',[0.5 0.5 0.5],...
                'Visible','on');
            
            testCase.verifyWarningFree(fcn)
            
        end %function
        
    end %methods(Test)
    
end %classdef