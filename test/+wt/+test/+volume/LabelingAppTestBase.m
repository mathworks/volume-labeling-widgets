classdef (Abstract) LabelingAppTestBase < matlab.uitest.TestCase
    %LabelingAppTestBase - Shared labeling app gesture regressions

    % Copyright 2026 The MathWorks, Inc.

    properties (Access = protected)
        App
        ClickPoints
    end

    methods (Access = protected)
        function createApp(testCase, constructor, kind)
            import matlab.unittest.constraints.Eventually
            import matlab.unittest.constraints.IsTrue
            hadApp = evalin('base', 'exist(''app'', ''var'') == 1');
            previousApp = [];
            if hadApp
                previousApp = evalin('base', 'app');
            end
            testCase.addTeardown(@restoreWorkspaceApp, hadApp, previousApp);
            group = matlab.lang.makeValidName(func2str(constructor));
            preferences = [];
            if ispref(group)
                preferences = getpref(group);
            end
            testCase.addTeardown(@restorePreferences, group, preferences);
            testCase.App = constructor();
            testCase.addTeardown(@cleanupApp, testCase.App);
            testCase.App.Figure.Position = [100 100 1100 750];
            if kind == "volume"
                model = wt.model.VolumeModel('ImageData', ...
                    repmat(uint8(100), 20, 20, 8));
                testCase.App.VolumeModel = model;
                testCase.App.AnnotationViewer.Slice = 4;
            else
                model = wt.model.IsosurfaceModel( ...
                    'Vertices', [1 1 1; 20 1 1; 20 20 1; 1 20 1], ...
                    'Faces', [1 2 3; 1 3 4]);
                testCase.App.IsosurfaceModel = model;
                viewer = testCase.App.AnnotationViewer;
                testCase.assertThat(@()isscalar(viewer.IsoPatch) && ...
                    isvalid(viewer.IsoPatch) && ...
                    isequal(viewer.IsoPatch.Vertices, model.Vertices), ...
                    Eventually(IsTrue, 'WithTimeoutOf', 20));
            end
            ax = testCase.App.AnnotationViewer.Axes;
            if kind == "volume"
                ax.View = [0 -90];
            else
                % A 3D view keeps Rotate available. Fixed limits prevent
                % a flat surface from rescaling between press and release.
                ax.XLim = [1 20];
                ax.YLim = [1 20];
                ax.ZLim = [0 2];
                ax.View = [0 45];
            end
            drawnow
            x = ax.XLim(1) + diff(ax.XLim) * [0.3; 0.6; 0.45];
            y = ax.YLim(1) + diff(ax.YLim) * [0.3; 0.4; 0.65];
            testCase.ClickPoints = [x y repmat(mean(ax.ZLim), 3, 1)];
        end

        function verifyAnnotation(testCase, pointCount)
            import matlab.unittest.constraints.Eventually
            import matlab.unittest.constraints.IsEqualTo
            testCase.verifyThat(@()size(testCase.App.AnnotationModel(1).Points, 1), ...
                Eventually(IsEqualTo(pointCount), 'WithTimeoutOf', 20));
            annotation = testCase.App.AnnotationModel(1);
            testCase.verifyEqual(annotation.Points(:, [2 1]), ...
                testCase.ClickPoints(1:pointCount, 1:2), 'AbsTol', 0.1);
            testCase.verifyTrue(annotation.HasLine);
            testCase.verifyEqual(annotation.Plot(1).Parent, ...
                testCase.App.AnnotationViewer.Axes);
            testCase.verifyEqual(string(annotation.Plot(1).Visible), "on");
            testCase.verifyGreaterThanOrEqual( ...
                sum(all(isfinite(annotation.Plot(1).Vertices), 2)), pointCount);
            testCase.verifyEqual(testCase.App.AnnotationList.AnnotationModel, annotation);
            table = testCase.annotationTable();
            testCase.verifyThat(@()size(get(table, 'Data'), 1), ...
                Eventually(IsEqualTo(1), 'WithTimeoutOf', 20));
        end

        function button = modeButton(testCase, tag)
            buttons = testCase.App.AnnotationViewer.Axes.Toolbar.Children;
            tags = get(buttons, {'Tag'});
            button = buttons(strcmp(tags, tag));
            testCase.assertNumElements(button, 1);
        end

        function table = annotationTable(testCase)
            children = allchild(testCase.App.AnnotationList.Grid);
            types = get(children, {'Type'});
            table = children(strcmp(types, 'uitable'));
            testCase.assertNumElements(table, 1);
        end

        function verifySuppression(testCase, tag)
            testCase.press(testCase.App.PointsButton);
            ax = testCase.App.AnnotationViewer.Axes;
            [viewProperties, viewValues] = testCase.captureView();
            testCase.setInteractionMode(tag, 'on');
            testCase.verifyWarningFree(@()testCase.press( ...
                ax, testCase.ClickPoints(1, :)));
            testCase.verifyEmpty(testCase.App.AnnotationModel(1).Points);
            testCase.setInteractionMode(tag, 'off');
            testCase.restoreView(viewProperties, viewValues);
            testCase.press(ax, testCase.ClickPoints(1, :));
            testCase.verifyAnnotation(1);
        end

        function setInteractionMode(testCase, tag, state)
            import matlab.unittest.constraints.Eventually
            import matlab.unittest.constraints.IsEqualTo
            button = testCase.modeButton(tag);
            try
                testCase.press(button);
            catch exception
                if ~strcmp(exception.identifier, ...
                        'MATLAB:uiautomation:Driver:GestureNotSupportedForClass')
                    rethrow(exception)
                end
                % Older drivers do not support the modern toolbar classes.
                % Public axes mode APIs activate the same toolbar state.
                ax = testCase.App.AnnotationViewer.Axes;
                switch tag
                    case 'zoomin'
                        zoom(ax, state);
                    case 'pan'
                        pan(ax, state);
                    case 'rotate'
                        rotate3d(ax, state);
                end
            end
            testCase.assertThat(@()wt.internal.isToolbarModeActive( ...
                testCase.App.AnnotationViewer.Axes.Toolbar.Children, tag), ...
                Eventually(IsEqualTo(strcmp(state, 'on')), 'WithTimeoutOf', 20));
        end

        function [properties, values] = captureView(testCase)
            properties = {'XLim', 'YLim', 'ZLim', 'DataAspectRatio', ...
                'PlotBoxAspectRatio', 'Projection', 'CameraPosition', ...
                'CameraTarget', 'CameraUpVector', 'CameraViewAngle'};
            values = get(testCase.App.AnnotationViewer.Axes, properties);
        end

        function restoreView(testCase, properties, values)
            import matlab.unittest.constraints.Eventually
            import matlab.unittest.constraints.IsEqualTo
            import matlab.unittest.constraints.IsTrue
            ax = testCase.App.AnnotationViewer.Axes;
            % A zoom click changes the camera. Restore it before reusing
            % the original world coordinate to test resumed editing.
            set(ax, properties, values);
            testCase.assertThat(@()get(ax, properties), ...
                Eventually(IsEqualTo(values), 'WithTimeoutOf', 20));
            testCase.assertThat(@()hasRenderedFrame(ax), ...
                Eventually(IsTrue, 'WithTimeoutOf', 20));
        end
    end

    methods (Test)
        function testLaunchAndModelDisplay(testCase)
            testCase.verifyEqual(string(testCase.App.Figure.Visible), "on");
            testCase.verifyEmpty(testCase.App.AnnotationModel);
            testCase.verifyFalse(logical(testCase.App.AnnotationViewer.ZoomActive));
            plots = findall(testCase.App.AnnotationViewer.Axes, ...
                'Type', 'surface', '-or', 'Type', 'patch');
            testCase.verifyNotEmpty(plots);
        end

        function testPointsFromAxesClick(testCase)
            testCase.press(testCase.App.PointsButton);
            testCase.press(testCase.App.AnnotationViewer.Axes, testCase.ClickPoints(1, :));
            testCase.verifyAnnotation(1);
        end

        function testLineFromAxesClicks(testCase)
            testCase.press(testCase.App.LineButton);
            testCase.press(testCase.App.AnnotationViewer.Axes, testCase.ClickPoints(1, :));
            testCase.press(testCase.App.AnnotationViewer.Axes, testCase.ClickPoints(2, :));
            testCase.verifyAnnotation(2);
        end

        function testPolygonFromAxesClicks(testCase)
            testCase.press(testCase.App.PolygonButton);
            testCase.press(testCase.App.AnnotationViewer.Axes, testCase.ClickPoints(1, :));
            testCase.press(testCase.App.AnnotationViewer.Axes, testCase.ClickPoints(2, :));
            testCase.press(testCase.App.AnnotationViewer.Axes, testCase.ClickPoints(3, :));
            testCase.verifyAnnotation(3);
        end

        function testFinishSelectEditDelete(testCase)
            import matlab.unittest.constraints.Eventually
            import matlab.unittest.constraints.IsEqualTo
            testCase.press(testCase.App.PointsButton);
            testCase.press(testCase.App.AnnotationViewer.Axes, testCase.ClickPoints(1, :));
            testCase.verifyAnnotation(1);
            testCase.press(testCase.App.FinishButton);
            testCase.verifyFalse(testCase.App.AnnotationModel(1).IsBeingEdited);
            testCase.press(testCase.App.SelectButton);
            testCase.press(testCase.App.AnnotationViewer.Axes, testCase.ClickPoints(1, :));
            testCase.verifyTrue(testCase.App.AnnotationModel(1).IsSelected);
            testCase.press(testCase.App.EditButton);
            testCase.verifyTrue(testCase.App.AnnotationModel(1).IsBeingEdited);
            testCase.press(testCase.App.FinishButton);
            testCase.press(testCase.App.DeleteButton);
            testCase.verifyThat(@()numel(testCase.App.AnnotationModel), ...
                Eventually(IsEqualTo(0), 'WithTimeoutOf', 20));
            table = testCase.annotationTable();
            testCase.verifyThat(@()size(get(table, 'Data'), 1), ...
                Eventually(IsEqualTo(0), 'WithTimeoutOf', 20));
        end

        function testZoomSuppressesEditing(testCase)
            testCase.verifySuppression('zoomin');
        end

        function testPanSuppressesEditing(testCase)
            testCase.verifySuppression('pan');
        end

        function testEditingWithoutToolbar(testCase)
            testCase.press(testCase.App.PointsButton);
            delete(testCase.App.AnnotationViewer.Axes.Toolbar);
            testCase.press(testCase.App.AnnotationViewer.Axes, testCase.ClickPoints(1, :));
            testCase.verifyAnnotation(1);
        end

        function testToolbarReplacementDuringEditing(testCase)
            testCase.press(testCase.App.PointsButton);
            testCase.press(testCase.App.AnnotationViewer.Axes, testCase.ClickPoints(1, :));
            delete(testCase.App.AnnotationViewer.Axes.Toolbar);
            axtoolbar(testCase.App.AnnotationViewer.Axes, {'zoomin', 'pan'});
            [viewProperties, viewValues] = testCase.captureView();
            testCase.setInteractionMode('zoomin', 'on');
            testCase.press(testCase.App.AnnotationViewer.Axes, testCase.ClickPoints(2, :));
            testCase.verifyEqual(size(testCase.App.AnnotationModel(1).Points, 1), 1);
            testCase.setInteractionMode('zoomin', 'off');
            testCase.restoreView(viewProperties, viewValues);
            testCase.press(testCase.App.AnnotationViewer.Axes, testCase.ClickPoints(2, :));
            testCase.verifyAnnotation(2);
        end
    end
end

function rendered = hasRenderedFrame(ax)
frame = getframe(ax);
rendered = ~isempty(frame.cdata);
end

function cleanupApp(app)
if isvalid(app)
    viewer = app.AnnotationViewer;
    if isvalid(viewer) && ~isempty(viewer.CurrentTool)
        viewer.CurrentTool.stop();
    end
    delete(app);
end
end

function restoreWorkspaceApp(hadApp, previousApp)
if hadApp
    assignin('base', 'app', previousApp);
else
    evalin('base', 'clear app');
end
end

function restorePreferences(group, preferences)
if ispref(group)
    rmpref(group);
end
if ~isempty(preferences)
    names = fieldnames(preferences);
    setpref(group, names, struct2cell(preferences));
end
end
