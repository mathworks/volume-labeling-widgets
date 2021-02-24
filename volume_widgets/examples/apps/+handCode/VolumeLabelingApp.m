classdef VolumeLabelingApp < handCode.BaseLabelingApp
    % A volume annotation labeling example app using hand code
    %
    % This is intended as an example showing how to build a hand-coded app
    % using object-oriented programming.

    % Copyright 2020-2021 The MathWorks, Inc.


    %% Public properties
    properties (Dependent, Access = public)

        % The imagery volume
        VolumeModel (1,1) wt.model.VolumeModel

    end %properties


    %% Protected properties
    properties (Access = protected)

        % Listeners to mouse wheel to change slice
        MouseWheelListener event.listener

    end %properties


    %% Protected methods
    methods (Access = protected)

        function setup(app)

            % Send app object to workspace (for debugging)
            assignin("base","app",app);

            % Call superclass update
            app.setup@handCode.BaseLabelingApp();

            % Customize the app name
            app.Name = 'Volume Labeling - Example MATLAB App';

            % Create AnnotationViewer
            app.AnnotationViewer = wt.VolumeQuadLabeler(app.Grid);
            app.AnnotationViewer.Layout.Row = [1 2];
            app.AnnotationViewer.Layout.Column = 1;

            % Create MaskPanel
            app.MaskPanel = uipanel(app.ToolsGridLayout);
            app.MaskPanel.ForegroundColor = [0.9412 0.9412 0.9412];
            app.MaskPanel.Title = 'Mask';
            app.MaskPanel.BackgroundColor = [0.149 0.149 0.149];
            app.MaskPanel.Layout.Row = 4;
            app.MaskPanel.Layout.Column = 1;
            app.MaskPanel.FontWeight = 'bold';
            app.MaskPanel.FontSize = 14;

            % Create MaskGridLayout
            app.MaskGridLayout = uigridlayout(app.MaskPanel);
            app.MaskGridLayout.ColumnWidth = {'1x'};
            app.MaskGridLayout.RowHeight = {40, 40, 40, 'fit', 'fit'};
            app.MaskGridLayout.ColumnSpacing = 2;
            app.MaskGridLayout.RowSpacing = 2;
            app.MaskGridLayout.Padding = [2 2 2 2];
            app.MaskGridLayout.BackgroundColor = [0.149 0.149 0.149];

            % Create MaskBrushButton
            app.MaskBrushButton = uibutton(app.MaskGridLayout, 'state');
            app.MaskBrushButton.ValueChangedFcn = createCallbackFcn(app, @MaskBrushButtonValueChanged, true);
            app.MaskBrushButton.Icon = 'brush_32.png';
            app.MaskBrushButton.Text = 'Brush';
            app.MaskBrushButton.BackgroundColor = [0.651 0.651 0.651];
            app.MaskBrushButton.FontColor = [1 1 1];
            app.MaskBrushButton.Layout.Row = 1;
            app.MaskBrushButton.Layout.Column = 1;

            % Create MaskEraseButton
            app.MaskEraseButton = uibutton(app.MaskGridLayout, 'state');
            app.MaskEraseButton.ValueChangedFcn = createCallbackFcn(app, @MaskEraseButtonValueChanged, true);
            app.MaskEraseButton.Icon = 'erase_24.png';
            app.MaskEraseButton.Text = 'Erase';
            app.MaskEraseButton.BackgroundColor = [0.651 0.651 0.651];
            app.MaskEraseButton.FontColor = [1 1 1];
            app.MaskEraseButton.Layout.Row = 2;
            app.MaskEraseButton.Layout.Column = 1;

            % Create MaskBrushSizeSlider
            app.MaskBrushSizeSlider = uislider(app.MaskGridLayout);
            app.MaskBrushSizeSlider.Limits = [1 101];
            app.MaskBrushSizeSlider.MajorTicks = [];
            app.MaskBrushSizeSlider.MajorTickLabels = {''};
            app.MaskBrushSizeSlider.ValueChangedFcn = createCallbackFcn(app, @MaskBrushSizeSliderValueChanged, true);
            app.MaskBrushSizeSlider.ValueChangingFcn = createCallbackFcn(app, @MaskBrushSizeSliderValueChanged, true);
            app.MaskBrushSizeSlider.MinorTicks = [];
            app.MaskBrushSizeSlider.FontColor = [0.9412 0.9412 0.9412];
            app.MaskBrushSizeSlider.Layout.Row = 5;
            app.MaskBrushSizeSlider.Layout.Column = 1;
            app.MaskBrushSizeSlider.Value = 1;

            % Create MaskInvertButton
            app.MaskInvertButton = uibutton(app.MaskGridLayout, 'push');
            app.MaskInvertButton.ButtonPushedFcn = createCallbackFcn(app, @MaskInvertButtonPushed, true);
            app.MaskInvertButton.Icon = 'invert_24.png';
            app.MaskInvertButton.BackgroundColor = [0.651 0.651 0.651];
            app.MaskInvertButton.FontColor = [1 1 1];
            app.MaskInvertButton.Tooltip = {''};
            app.MaskInvertButton.Layout.Row = 3;
            app.MaskInvertButton.Layout.Column = 1;
            app.MaskInvertButton.Text = 'Invert';

            % Create MaskBrushSizeLabel
            app.MaskBrushSizeLabel = uilabel(app.MaskGridLayout);
            app.MaskBrushSizeLabel.VerticalAlignment = 'bottom';
            app.MaskBrushSizeLabel.FontColor = [0.9412 0.9412 0.9412];
            app.MaskBrushSizeLabel.Layout.Row = 4;
            app.MaskBrushSizeLabel.Layout.Column = 1;
            app.MaskBrushSizeLabel.Text = 'Brush Size:';

            % When the mouse wheel moves (for changing slice)
            app.MouseWheelListener = event.listener(app.Figure,...
                'WindowScrollWheel',@(src,evt)app.onMouseWheel(evt));

        end %function


        function update(app)

            % Call superclass update
            app.update@handCode.BaseLabelingApp();

            % What tool is currently selected?
            selTool = app.AnnotationViewer.CurrentTool;

            % Mask section
            brushIsActive = ~isempty(selTool) && selTool.Type == "wt.tool.Brush";
            app.MaskBrushButton.Value = brushIsActive;
            app.MaskEraseButton.Enable = brushIsActive;
            app.MaskEraseButton.Value = brushIsActive && selTool.Erase;
            app.MaskInvertButton.Enable = brushIsActive;
            app.MaskBrushSizeLabel.Enable = brushIsActive;
            app.MaskBrushSizeSlider.Enable = brushIsActive;
            if brushIsActive
                app.MaskBrushSizeSlider.Value = selTool.BrushSize;
            end

        end %function


        function onMouseWheel(app,e)

            % Get mouse position within figure
            mousePos = app.Figure.CurrentPoint;

            % Get the scroll amount/direction
            scrollAmount = -e.VerticalScrollCount;

            % Get axes positions
            mainPos = getpixelposition(app.AnnotationViewer.Axes.Parent, true);
            sidePos = getpixelposition(app.AnnotationViewer.SideView.Axes.Parent, true);
            topPos = getpixelposition(app.AnnotationViewer.TopView.Axes.Parent, true);

            % Get the selected viewer that mouse is over
            if inBox(mainPos)
                selViewer = app.AnnotationViewer;
            elseif inBox(sidePos)
                selViewer = app.AnnotationViewer.SideView;
            elseif inBox(topPos)
                selViewer = app.AnnotationViewer.TopView;
            else
                return
            end

            % Only proceed if zoom is not enabled
            if ~selViewer.ZoomActive

                % Change slice
                selViewer.Slice = max(1, selViewer.Slice + scrollAmount);

            end %if ~isZoomPan(selViewer.Axes)

            % Helper function - detect if in the axes bounds
            function tf = inBox(boxPos)
                tf = mousePos(1) > boxPos(1) && ...
                    mousePos(1) < (boxPos(1) + boxPos(3)) && ...
                    mousePos(2) > boxPos(2) && ...
                    mousePos(2) < (boxPos(2) + boxPos(4));
            end

        end %function

    end %methods

end %classdef