classdef VolumeLabelingApp < handCode.BaseLabelingApp
    % A volume annotation labeling example app using hand code
    %
    % This is intended as an example showing how to build a hand-coded app
    % using object-oriented programming.

    % Copyright 2020-2021 The MathWorks, Inc.
    %#ok<*INUSD>


    %% Public properties
    properties (Dependent, Access = public)

        % The imagery volume
        VolumeModel (1,1) wt.model.VolumeModel

    end %properties


    %% Protected properties
    properties (Access = protected)

        % Listeners to mouse wheel to change slice
        MouseWheelListener event.listener
        
        MaskPanel                   matlab.ui.container.Panel
        MaskGridLayout              matlab.ui.container.GridLayout
        MaskBrushSizeLabel          matlab.ui.control.Label
        MaskInvertButton            matlab.ui.control.Button
        MaskBrushSizeSlider         matlab.ui.control.Slider
        MaskEraseButton             matlab.ui.control.StateButton
        MaskBrushButton             matlab.ui.control.StateButton

    end %properties


    %% Protected methods
    methods (Access = protected)

        function setup(app)

            % Customize the app name and icon
            app.Name = 'Volume Labeling - Example Hand-Coded MATLAB App';
            app.Figure.Icon = 'volume_labeling_toolbox_icon.png';

            % Create AnnotationViewer
            app.AnnotationViewer = wt.VolumeQuadLabeler(app.Grid);
            app.AnnotationViewer.Layout.Row = [1 2];
            app.AnnotationViewer.Layout.Column = 1;

            % Call superclass method
            app.setup@handCode.BaseLabelingApp();

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

            % Call superclass method
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


        % Button pushed function: LoadButton
        function LoadButtonPushed(app, ~)

            % Prompt for a filename
            pathName = uigetdir(app.LastPath, "Import DICOM Volume");

            % Return now if the user cancelled
            if isequal(pathName,0)
                return
            end

            % Trap errors
            try
                % Load the dicom file
                volModel = wt.model.VolumeModel.fromDicomFile(pathName);

                % Keep track of the last directory used
                app.LastPath = pathName;

                % Store the new volume
                app.VolumeModel = volModel;

            catch err

                % Send error to a dialog
                dlg = errordlg(['Not a valid dicom volume. ' err.message]);
                uiwait(dlg);

            end

            % Update the display
            app.update();

        end %function

        % Value changed function: MaskBrushButton
        function MaskBrushButtonValueChanged(app, event)

            % Get the new value
            value = app.MaskBrushButton.Value;

            % Was the button turned on or off?
            if value

                % Make a new annotation
                % For a mask, we need to match the size of the
                % corresponding volume model on creation
                a = wt.model.MaskAnnotation.fromVolumeModel(...
                    app.VolumeModel,...
                    'Name',app.getNewAnnotationName(),...
                    'Color',app.getNewAnnotationColor(),...
                    'Alpha',0.5);

                % Add the annotation to the viewer and launch the tool
                app.AnnotationViewer.addInteractiveAnnotation(a);

            else

                % Turned off, so finish the annotation
                app.AnnotationViewer.finishAnnotation();

            end

            % Update the display
            app.update();

        end

        % Value changed function: MaskEraseButton
        function MaskEraseButtonValueChanged(app, event)

            % Get the new value
            value = app.MaskEraseButton.Value;

            % Tell the mask brush tool to switch to erase mode
            app.AnnotationViewer.CurrentTool.Erase = value;

            % Update the display
            app.update();

        end

        % Button pushed function: MaskInvertButton
        function MaskInvertButtonPushed(app, event)

            % Tell the mask brush tool to invert the mask
            app.AnnotationViewer.CurrentTool.invert();

            % Update the display
            app.update();

        end

        % Callback function: MaskBrushSizeSlider, MaskBrushSizeSlider
        function MaskBrushSizeSliderValueChanged(app, event)

            % Get the new value
            value = event.Value;

            % Must integer
            value = max(ceil(value), 1);

            % Should be an odd number if > 2
            if value > 2 && ~mod(value,2)
                value = value + 1;
            end

            % Tell the mask brush tool to update brush size
            app.AnnotationViewer.CurrentTool.BrushSize = value;

            % Update the display
            app.update();

        end
        
        % Button pushed function: ControlsButton
        function ControlsButtonPushed(app, event)

            % Pop up the help for mouse controls
            title = "Annotation Tools";
            message = [
                "Adding/Edit Point-based Annotations:"
                "Left-click adds points."
                "Left-click and drag an existing point moves it."
                "Right-click an existing point deletes it."
                "Double-click finishes"
                ""
                "Adding/Edit Brush-based Annotations:"
                "Left button draws."
                "Right button erases."
                "Double-click finishes"
                ""
                "Note: Editing will be temporarily disabled while in a zoom/pan/rotate mode."
                ];

            uialert(app.Figure, message, title, 'Icon', 'info');

        end

    end %methods


    % Get/Set methods
    methods

        function value = get.VolumeModel(app)
            value = app.AnnotationViewer.VolumeModel;
        end

        function set.VolumeModel(app, value)
            if ~isequal(app.AnnotationViewer.VolumeModel, value)
                app.deleteAllAnnotations();
                app.AnnotationViewer.VolumeModel = value;
            end
        end

    end %methods

end %classdef