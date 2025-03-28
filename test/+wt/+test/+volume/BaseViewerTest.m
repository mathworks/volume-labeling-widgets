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

            % Position it off the non-primary monitor if possible
            % This gets it away from the editor when writing tests
            persistent startPos
            if isempty(startPos)
                startPos = findPreferredPosition(testCase);
            end

            % Create the figure
            testCase.Figure = uifigure('Position',[startPos 600 600]);
            testCase.Figure.Name = "Unit Test - " + class(testCase);

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


    %% Helper Methods
    methods (Access = protected)

        function pos = findPreferredPosition(~)
            % Callback when a button is pressed

            % Position it off the non-primary monitor if possible
            % This gets it away from the editor when writing tests
            monitorPositions = get(0, 'MonitorPositions');

            if isempty(monitorPositions)

                % Shouldn't happen, but just in case
                % Leave space for taskbar
                pos = [1 100];

            elseif size(monitorPositions,1) == 1

                % Primary monitor
                monIdx = 1;

                % Get position
                % Leave space for taskbar
                pos = monitorPositions(monIdx, 1:2) + [1 100];

            else
                % Secondary monitors available

                % Find the primary monitor
                isPrimary = all(monitorPositions(:,1:2) == [1 1], 2);

                % If multiple non-primary, choose the last one
                monIdx = find(~isPrimary,1,'last');

                % If none found, revert to the primary
                if isempty(monIdx)
                    monIdx = 1;
                end

                % Use the lower-left corner of the selected monitor
                % Leave space for taskbar

                % Get position
                pos = monitorPositions(monIdx, 1:2) + [1 100];

            end %if

        end %function


        function assumeMinimumRelease(testCase, releaseName)
            % Callback when a button is pressed

            isUnsupported = isMATLABReleaseOlderThan(releaseName);
            diag = "Release not supported.";
            testCase.assumeFalse(isUnsupported, diag)

        end %function

    end %methods

end %classdef