classdef TestVolumeLabelingApps < wt.test.volume.LabelingAppTestBase
    %TestVolumeLabelingApps - Test hand-coded and App Designer volume demos

    % Copyright 2026 The MathWorks, Inc.

    properties (MethodSetupParameter)
        AppConstructor = struct('HandCoded', @handCode.VolumeLabelingApp, ...
            'AppDesigner', @VolumeLabelingExample)
    end

    properties (TestParameter)
        ScrollView = struct('Main', 'main', 'Top', 'top', 'Side', 'side')
        BrushView = struct('XY', 'XY', 'XZ', 'XZ', 'YZ', 'YZ')
    end

    methods (TestMethodSetup)
        function launchApp(testCase, AppConstructor)
            testCase.createApp(AppConstructor, "volume");
        end
    end

    methods (Test)
        function testMRIImageAndAnnotationDisplay(testCase)
            import matlab.unittest.constraints.Eventually
            import matlab.unittest.constraints.IsEqualTo
            import matlab.unittest.constraints.IsTrue
            data = load('mristack.mat');
            testCase.App.VolumeModel = wt.model.VolumeModel( ...
                'ImageData', data.mristack);
            viewer = testCase.App.AnnotationViewer;
            viewer.Slice = 12;
            testCase.assertThat(@()viewer.Image.CData, ...
                Eventually(IsEqualTo(data.mristack(:, :, 12)), ...
                'WithTimeoutOf', 20));
            testCase.verifyThat(@()renderedMRIHasContrast(viewer.Axes), ...
                Eventually(IsTrue, 'WithTimeoutOf', 20), ...
                'The rendered MRI should contain image detail, not a blank gray area.');
            testCase.assertFalse(renderedAnnotationHasColor(viewer.Axes));
            testCase.press(testCase.App.PointsButton);
            clickPoint = [mean(viewer.Axes.XLim), mean(viewer.Axes.YLim), ...
                mean(viewer.Axes.ZLim)];
            testCase.press(viewer.Axes, clickPoint);
            testCase.verifyThat(@()renderedAnnotationHasColor(viewer.Axes), ...
                Eventually(IsTrue, 'WithTimeoutOf', 20), ...
                'The annotation marker should render over the grayscale MRI.');
        end

        function testRenderingCheckRejectsUniformImage(testCase)
            testCase.verifyFalse(renderedMRIHasContrast( ...
                testCase.App.AnnotationViewer.Axes));
        end

        function testWheelChangesSlice(testCase, ScrollView)
            import matlab.unittest.constraints.Eventually
            import matlab.unittest.constraints.IsEqualTo
            testCase.assumeFalse(isMATLABReleaseOlderThan('R2024a'), ...
                'Automated scroll gestures require R2024a or later.');
            viewer = testCase.scrollViewer(ScrollView);
            viewer.Slice = 4;
            drawnow
            testCase.scroll(viewer.Axes, 'up');
            testCase.verifyThat(@()viewer.Slice, ...
                Eventually(IsEqualTo(5), 'WithTimeoutOf', 20));
            testCase.scroll(viewer.Axes, 'down');
            testCase.verifyThat(@()viewer.Slice, ...
                Eventually(IsEqualTo(4), 'WithTimeoutOf', 20));
        end

        function testWheelSliceLimits(testCase)
            import matlab.unittest.constraints.Eventually
            import matlab.unittest.constraints.IsEqualTo
            testCase.assumeFalse(isMATLABReleaseOlderThan('R2024a'));
            viewer = testCase.App.AnnotationViewer;
            viewer.Slice = 1;
            drawnow
            testCase.scroll(viewer.Axes, 'down');
            testCase.verifyEqual(viewer.Slice, 1);
            viewer.Slice = testCase.App.VolumeModel.DataSize(3);
            drawnow
            testCase.scroll(viewer.Axes, 'up');
            testCase.verifyThat(@()viewer.Slice, ...
                Eventually(IsEqualTo(testCase.App.VolumeModel.DataSize(3)), ...
                'WithTimeoutOf', 20));
        end

        function testZoomSuppressesWheel(testCase)
            testCase.assumeFalse(isMATLABReleaseOlderThan('R2024a'));
            testCase.setInteractionMode('zoomin', 'on');
            testCase.scroll(testCase.App.AnnotationViewer.Axes, 'up');
            testCase.verifyEqual(testCase.App.AnnotationViewer.Slice, 4);
            testCase.setInteractionMode('zoomin', 'off');
        end

        function testBrushAndErase(testCase)
            import matlab.unittest.constraints.Eventually
            import matlab.unittest.constraints.IsEqualTo
            import matlab.unittest.constraints.IsTrue
            brush = findall(testCase.App.Figure, 'Type', 'uistatebutton', 'Text', 'Brush');
            erase = findall(testCase.App.Figure, 'Type', 'uistatebutton', 'Text', 'Erase');
            testCase.assertNumElements(brush, 1);
            testCase.assertNumElements(erase, 1);
            testCase.press(brush);
            testCase.press(testCase.App.AnnotationViewer.Axes, testCase.ClickPoints(1, :));
            annotation = testCase.App.AnnotationModel(1);
            testCase.verifyGreaterThan(nnz(annotation.Mask), 0);
            testCase.press(erase);
            testCase.assertThat(@()testCase.App.AnnotationViewer.CurrentTool.Erase, ...
                Eventually(IsTrue, 'WithTimeoutOf', 20));
            testCase.press(testCase.App.AnnotationViewer.Axes, testCase.ClickPoints(1, :));
            testCase.verifyThat(@()nnz(annotation.Mask), ...
                Eventually(IsEqualTo(0), 'WithTimeoutOf', 20));
        end

        function testBrushUsesDisplayedSlice(testCase, BrushView)
            import matlab.unittest.constraints.Eventually
            import matlab.unittest.constraints.IsEqualTo
            import matlab.unittest.constraints.IsTrue
            viewer = testCase.App.AnnotationViewer;
            testCase.choose(viewer.ViewIndicator, BrushView);
            viewer.Slice = 4;
            drawnow
            point = [mean(viewer.Axes.XLim), mean(viewer.Axes.YLim), ...
                mean(viewer.Axes.ZLim)];
            brush = findall(testCase.App.Figure, 'Type', 'uistatebutton', 'Text', 'Brush');
            erase = findall(testCase.App.Figure, 'Type', 'uistatebutton', 'Text', 'Erase');
            testCase.press(brush);
            testCase.press(viewer.Axes, point);
            annotation = testCase.App.AnnotationModel(1);
            testCase.assertGreaterThan(nnz(annotation.Mask), 0);
            coordinates = cell(1, 3);
            [coordinates{:}] = ind2sub(size(annotation.Mask), find(annotation.Mask));
            testCase.verifyEqual(unique(coordinates{viewer.SliceDimension}), viewer.Slice);
            testCase.press(erase);
            testCase.assertThat(@()viewer.CurrentTool.Erase, ...
                Eventually(IsTrue, 'WithTimeoutOf', 20));
            testCase.press(viewer.Axes, point);
            testCase.verifyThat(@()nnz(annotation.Mask), ...
                Eventually(IsEqualTo(0), 'WithTimeoutOf', 20));
        end
    end

    methods (Access = private)
        function viewer = scrollViewer(testCase, name)
            switch name
                case 'main'
                    viewer = testCase.App.AnnotationViewer;
                case 'top'
                    viewer = testCase.App.AnnotationViewer.TopView;
                case 'side'
                    viewer = testCase.App.AnnotationViewer.SideView;
            end
        end
    end
end

function hasContrast = renderedMRIHasContrast(ax)
% Exclude toolbar buttons and plot edges from the rendered image check.
pixels = centralRenderedPixels(ax);
if isempty(pixels)
    hasContrast = false;
    return
end
gray = pixels(:, :, 1);
hasContrast = (max(gray(:)) - min(gray(:))) > 40 && ...
    std(gray(:)) > 12 && numel(unique(gray)) > 16;
end

function hasColor = renderedAnnotationHasColor(ax)
pixels = centralRenderedPixels(ax);
channelRange = max(pixels, [], 3) - min(pixels, [], 3);
hasColor = nnz(channelRange > 40) > 4;
end

function pixels = centralRenderedPixels(ax)
frame = getframe(ax);
pixels = frame.cdata;
if isempty(pixels)
    return
end
rows = ceil(size(pixels, 1) * 0.2):floor(size(pixels, 1) * 0.8);
columns = ceil(size(pixels, 2) * 0.2):floor(size(pixels, 2) * 0.8);
pixels = double(pixels(rows, columns, :));
end
