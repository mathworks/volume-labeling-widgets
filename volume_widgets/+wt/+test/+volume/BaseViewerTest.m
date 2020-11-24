classdef BaseViewerTest < matlab.uitest.TestCase
    % Unit Test - Implements a unit test for a widget or component
    
    % Copyright 2020 The MathWorks,Inc.
    
    
    %% Properties
    properties
        Figure
        Parent
    end
    
    %% Test Class Setup / Teardown
    methods (TestClassSetup)
        
        function createFigure(testCase)
            
            testCase.Figure = uifigure('Position',[100 100 1400 800]);
            testCase.Parent = uigridlayout(testCase.Figure);
            testCase.Parent.ColumnWidth = {'1x','1x','1x','1x'};
            testCase.Parent.RowHeight = {'1x','1x','1x'};
            testCase.Parent.Padding = [0 0 0 0];
            
        end %function
        
    end %methods (TestClassSetup)
    
    
    methods (TestClassTeardown)
        
        function deleteFigure(testCase)
            
            delete(testCase.Figure)
            
        end %function
        
    end %methods (TestClassSetup)
    
    
end %classdef