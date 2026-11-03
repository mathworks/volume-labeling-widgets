classdef TestToolbarModes < matlab.unittest.TestCase
    %TestToolbarModes - Test defensive axes toolbar mode detection

    % Copyright 2026 The MathWorks, Inc.

    properties (TestParameter)
        InactiveTag = struct('Empty', '', 'Unknown', 'export', 'Invalid', 42)
        InactiveValue = struct('NaN', NaN, 'Vector', [true false], ...
            'Unknown', 'active', 'Empty', [])
    end

    methods (Test)
        function testEmptyChildren(testCase)
            testCase.verifyFalse(wt.internal.isToolbarModeActive( ...
                gobjects(0), 'zoom'));
        end

        function testUnrecognizedTag(testCase, InactiveTag)
            child = wt.test.volume.ToolbarChild;
            child.Tag = InactiveTag;
            testCase.verifyFalse(wt.internal.isToolbarModeActive(child, 'zoom'));
        end

        function testUnusableValue(testCase, InactiveValue)
            child = wt.test.volume.ToolbarChild;
            child.Value = InactiveValue;
            testCase.verifyFalse(wt.internal.isToolbarModeActive(child, 'zoom'));
        end

        function testUnreadableTag(testCase)
            child = wt.test.volume.ToolbarChild;
            child.TagReadable = false;
            testCase.verifyFalse(wt.internal.isToolbarModeActive(child, 'zoom'));
        end

        function testUnreadableValue(testCase)
            child = wt.test.volume.ToolbarChild;
            child.ValueReadable = false;
            testCase.verifyFalse(wt.internal.isToolbarModeActive(child, 'zoom'));
        end

        function testUntaggedChildDoesNotHideActiveMode(testCase)
            untagged = wt.test.volume.ToolbarChild;
            untagged.TagReadable = false;
            active = wt.test.volume.ToolbarChild;
            testCase.verifyTrue(wt.internal.isToolbarModeActive( ...
                [untagged active], 'zoom'));
        end

        function testDeletedChild(testCase)
            child = wt.test.volume.ToolbarChild;
            delete(child);
            testCase.verifyFalse(wt.internal.isToolbarModeActive(child, 'zoom'));
        end

        function testLiveToolbarAndReplacement(testCase)
            fig = uifigure;
            testCase.addTeardown(@delete, fig);
            viewer = wt.VolumeViewer(fig);
            testCase.verifyFalse(logical(viewer.ZoomActive));
            buttons = viewer.Axes.Toolbar.Children;
            zoomButton = buttons(contains(get(buttons, {'Tag'}), 'zoomin'));
            set(zoomButton, 'Value', 'on');
            testCase.verifyTrue(logical(viewer.ZoomActive));
            delete(viewer.Axes.Toolbar);
            testCase.verifyFalse(logical(viewer.ZoomActive));
            toolbar = axtoolbar(viewer.Axes, {'pan', 'zoomin'});
            buttons = toolbar.Children;
            zoomButton = buttons(contains(get(buttons, {'Tag'}), 'zoomin'));
            set(zoomButton, 'Value', 'on');
            testCase.verifyTrue(logical(viewer.ZoomActive));
        end
    end
end
