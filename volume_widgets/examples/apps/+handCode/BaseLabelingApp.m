classdef (Abstract) BaseLabelingApp < wt.apps.BaseApp

    % Properties that correspond to app components
    properties (Access = public)
        FileGridLayout              matlab.ui.container.GridLayout
        ImportButton                matlab.ui.control.Button
        ExportButton                matlab.ui.control.Button
        LoadButton                  matlab.ui.control.Button
        AnnotationLabelsPanel       matlab.ui.container.Panel
        AnnotationLabelsGridLayout  matlab.ui.container.GridLayout
        AnnotationList              wt.AnnotationLabelsList
        ToolsGridLayout             matlab.ui.container.GridLayout
        ControlsButton              matlab.ui.control.Button
        EditPanel                   matlab.ui.container.Panel
        EditGridLayout              matlab.ui.container.GridLayout
        ColorGridLayout             matlab.ui.container.GridLayout
        ColorLabel                  matlab.ui.control.Label
        ColorSelector               wt.ColorSelector
        FinishButton                matlab.ui.control.Button
        DeleteButton                matlab.ui.control.Button
        EditButton                  matlab.ui.control.Button
        SelectButton                matlab.ui.control.StateButton
        ShapesPanel                 matlab.ui.container.Panel
        ShapesGridLayout            matlab.ui.container.GridLayout
        LineButton                  matlab.ui.control.StateButton
        PlaneButton                 matlab.ui.control.StateButton
        PolygonButton               matlab.ui.control.StateButton
        PointsButton                matlab.ui.control.StateButton
        AnnotationViewer            wt.abstract.BaseAxesViewer
    end


    % Copyright 2020-2021 The MathWorks, Inc.
    %#ok<*INUSD>


    % Public properties
    properties (Dependent, Access = public)

        % Annotations
        AnnotationModel (1,:) wt.model.BaseAnnotationModel

        % Show or hide the axes, ticks, etc.
        ShowAxes (1,1) logical

        % Show or hide the grid
        ShowGrid (1,1) logical

    end %properties


    % Protected properties
    properties (Transient, NonCopyable, Access = protected)

        % Most recent directory path for save/load
        LastPath (1,1) string {mustBeFolder} = userpath()

        % Listeners to Annotation changes
        AnnotationChangedListener event.listener

        % When the selected annotation changes
        AnnotationSelectedListener event.listener

        % When the array of AnnotationModel has changed
        AnnotationModelChangedListener event.listener

    end %properties


    % Protected methods
    methods (Access = protected)

        function update(app)

            % What tool is currently selected?
            selTool = app.AnnotationViewer.CurrentTool;

            % Is an annotation selected?
            selAnn = app.AnnotationViewer.SelectedAnnotationModel;
            hasSelection = ~isempty(selAnn);
            if hasSelection
                annType = selAnn.Type;
            else
                annType = "";
            end

            % Is an annotation being edited?
            isEditing = app.AnnotationViewer.IsAddingInteractiveAnnotation;

            % Edit section
            hasAnnModels = ~isempty(app.AnnotationModel);
            app.SelectButton.Enable = hasAnnModels;
            app.SelectButton.Value = ~isempty(selTool) && selTool.Type == "wt.tool.Select";
            app.EditButton.Enable = hasSelection && ~isEditing;
            app.DeleteButton.Enable = hasSelection;
            app.FinishButton.Enable = hasSelection && isEditing;
            app.ColorSelector.Enable = hasSelection;
            app.ColorLabel.Enable = hasSelection;
            if hasSelection
                app.ColorSelector.Value = selAnn.Color;
            end

            % Shapes section
            isVerticesTool = ~isempty(selTool) && selTool.Type == "wt.tool.Vertices";
            app.PointsButton.Value = isVerticesTool && contains(annType, "Points");
            app.LineButton.Value = isVerticesTool && contains(annType, "Line");
            app.PolygonButton.Value = isVerticesTool && contains(annType, "Polygon");
            app.PlaneButton.Value = isVerticesTool && contains(annType, "Plane");

            % Annotation table
            allAnn = app.AnnotationModel;
            app.AnnotationList.AnnotationModel = allAnn;

        end %function


        function value = getNewAnnotationName(app)
            % Make a new and unique annotation name

            existingNames = vertcat("New_Annotation", app.AnnotationModel.Name);
            value = matlab.lang.makeUniqueStrings("New_Annotation", existingNames);

        end %function


        function value = getNewAnnotationColor(~)
            % Make a new and unique annotation color

            % Grab from a list of colors
            persistent colors nextRow
            if isempty(colors)
                colors = [
                    0         0.4470    0.7410
                    0.8500    0.3250    0.0980
                    0.9290    0.6940    0.1250
                    0.4940    0.1840    0.5560
                    0.4660    0.6740    0.1880
                    0.3010    0.7450    0.9330
                    0.6350    0.0780    0.1840
                    0         1         0
                    0         0         1
                    1         0         0
                    0         1         1
                    1         1         0
                    1         0         1
                    ];
                nextRow = 1;
            end

            % Return the next color
            value = colors(nextRow,:);
            if nextRow < size(colors,1)
                nextRow = nextRow + 1;
            else
                nextRow = 1;
            end

        end %function


        function onAnnotationModelChanged(app,evt)
            % When the data within an annotation model has changed

            % What has changed?
            switch evt.Property

                case {
                        %'IsSelected'
                        'IsBeingEdited'
                        'Color'
                        }

                    % Need to trigger update
                    app.update();

                otherwise
                    % Skip the update for efficient performance

            end %switch

        end %function


        function deleteAllAnnotations(app)
            % Removes annotations from the viewer

            app.AnnotationViewer.cancelAnnotation();
            app.AnnotationModel(:) = [];

        end %function

    end %methods


    % Get/Set methods
    methods

        function value = get.ShowAxes(app)
            value = app.AnnotationViewer.ShowAxes;
        end

        function set.ShowAxes(app,value)
            app.AnnotationViewer.ShowAxes = value;
        end

        function value = get.ShowGrid(app)
            value = app.AnnotationViewer.ShowGrid;
        end

        function set.ShowGrid(app,value)
            app.AnnotationViewer.ShowGrid = value;
        end

        function value = get.AnnotationModel(app)
            value = app.AnnotationViewer.AnnotationModel;
        end

        function set.AnnotationModel(app,value)
            app.AnnotationViewer.AnnotationModel = value;
        end

    end %methods

    % Abstract Protected Methods (subclass must implement)
    methods (Abstract, Access = protected)
        LoadButtonPushed(app, event)
    end %methods

    % Callbacks that handle component events
    methods (Access = protected)

        % Code that executes after component creation
        function setup(app)

            % Send app object to workspace (for debugging)
            assignin("base","app",app);

            % Create the components
            app.createComponents();

            %--- Attach listeners ---%

            % When the list of annotation models is changed
            app.AnnotationModelChangedListener = event.listener(...
                app.AnnotationViewer, "AnnotationModelChanged", ...
                @(src,evt)app.update() );

            % When an annotation is selected in the viewer
            app.AnnotationSelectedListener = event.listener(...
                app.AnnotationViewer, "AnnotationSelected", ...
                @(src,evt)app.update() );

            % When the data within an annotation model is changed
            app.AnnotationChangedListener = event.listener(...
                app.AnnotationViewer, "AnnotationChanged", ...
                @(src,evt)app.onAnnotationModelChanged(evt) );

        end


        % Button pushed function: ExportButton
        function ExportButtonPushed(app, event)

            % Prompt for a filename
            message = 'Export Annotations';
            pattern = {'*.mat','MATLAB MAT-file'};
            startPath = fullfile(app.LastPath, 'Annotations.mat');
            [fileName,pathName] = uiputfile(pattern,message,startPath);

            % Return now if the user cancelled
            if isequal(fileName,0)
                return
            end

            % Keep track of the last directory used
            app.LastPath = pathName;

            % Save the file
            filePath = fullfile(pathName,fileName);
            aObj = app.AnnotationModel;
            save(filePath,'aObj');

            % Update the display
            app.update();

        end

        % Button pushed function: ImportButton
        function ImportButtonPushed(app, event)

            % Prompt for a filename
            dlgTitle = "Import Labels";
            pattern = {'*.mat','MATLAB MAT-file'};
            [fileName,pathName] = uigetfile(pattern,dlgTitle,app.LastPath);

            % Return now if the user cancelled
            if isequal(fileName,0)
                return
            end

            % Keep track of the last directory used
            app.LastPath = pathName;

            % Load the file
            filePath = fullfile(pathName,fileName);
            s = load(filePath);

            % Check for valid annotation model data
            if isfield(s,'aObj') && isa(s.aObj,'wt.model.BaseAnnotationModel')

                % Import the data
                app.AnnotationViewer.removeAnnotation(app.AnnotationModel);
                app.AnnotationViewer.addAnnotation(s.aObj);

            else

                % Send error to a dialog
                msg = "Not a valid annotation labels file.";
                uialert(app.Figure, msg, dlgTitle);

            end

            % Update the display
            app.update();

        end

        % Value changed function: SelectButton
        function SelectButtonValueChanged(app, event)

            % Get the new value
            value = app.SelectButton.Value;

            % Was the button turned on or off?
            if value

                % On - launch the tool
                app.AnnotationViewer.launchSelectTool();

            else

                % Off - stop the tool
                selTool = app.AnnotationViewer.CurrentTool;
                selTool.stop();

            end

            % Update the display
            app.update();

        end

        % Button pushed function: EditButton
        function EditButtonPushed(app, event)

            % Edit the selected annotation
            selAnn = app.AnnotationViewer.SelectedAnnotationModel;
            app.AnnotationViewer.launchEditingTool(selAnn, false);

            % Update the display
            app.update();

        end

        % Button pushed function: DeleteButton
        function DeleteButtonPushed(app, event)

            % Delete the selected annotation
            selAnn = app.AnnotationViewer.SelectedAnnotationModel;
            app.AnnotationViewer.removeAnnotation(selAnn);

            % Update the display
            app.update();

        end

        % Button pushed function: FinishButton
        function FinishButtonPushed(app, event)

            % Finish editing the selected annotation
            app.AnnotationViewer.finishAnnotation();

            % Update the display
            app.update();

        end

        % Callback function: ColorSelector
        function ColorSelectorValueChanged(app, event)

            % Get the new value
            value = app.ColorSelector.Value;

            % Update the color of the selected annotation
            selAnn = app.AnnotationViewer.SelectedAnnotationModel;
            set(selAnn,"Color",value);

            % Update the display
            app.update();

        end

        % Value changed function: PointsButton
        function PointsButtonValueChanged(app, event)

            % Get the new value
            value = app.PointsButton.Value;

            % Was the button turned on or off?
            if value

                % Make a new annotation
                a = wt.model.PointsAnnotation(...
                    'Name',app.getNewAnnotationName(),...
                    'Color',app.getNewAnnotationColor() );

                % Add the annotation to the viewer and launch the tool
                app.AnnotationViewer.addInteractiveAnnotation(a);

            else

                % Turned off, so finish the annotation
                app.AnnotationViewer.finishAnnotation();

            end

            % Update the display
            app.update();

        end

        % Value changed function: LineButton
        function LineButtonValueChanged(app, event)

            % Get the new value
            value = app.LineButton.Value;

            % Was the button turned on or off?
            if value

                % Make a new annotation
                a = wt.model.LineAnnotation(...
                    'Name',app.getNewAnnotationName(),...
                    'Color',app.getNewAnnotationColor() );

                % Add the annotation to the viewer and launch the tool
                app.AnnotationViewer.addInteractiveAnnotation(a);

            else

                % Turned off, so finish the annotation
                app.AnnotationViewer.finishAnnotation();

            end

            % Update the display
            app.update();

        end

        % Value changed function: PolygonButton
        function PolygonButtonValueChanged(app, event)

            % Get the new value
            value = app.PolygonButton.Value;

            % Was the button turned on or off?
            if value

                % Make a new annotation
                a = wt.model.PolygonAnnotation(...
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

        % Value changed function: PlaneButton
        function PlaneButtonValueChanged(app, event)

            % Get the new value
            value = app.PlaneButton.Value;

            % Was the button turned on or off?
            if value

                % Make a new annotation
                a = wt.model.PlaneAnnotation(...
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

        % Callback function: AnnotationList
        function AnnotationListSelectionChanged(app, event)

            % Get the new selection
            selIdx = event.Value;
            aObjSel = app.AnnotationModel(selIdx);

            % Tell the viewer to select the new annotation
            app.AnnotationViewer.selectAnnotation(aObjSel);

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
                "Note: Editing will be temporarily disabled while in a zoom/pan/rotate mode."
                ];

            uialert(app.Figure, message, title, 'Icon', 'info');

        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create Grid
            app.Grid.ColumnWidth = {'1x', 100, 300};
            app.Grid.RowHeight = {160, '1x'};
            app.Grid.BackgroundColor = [0.149 0.149 0.149];

            % Create ToolsGridLayout
            app.ToolsGridLayout = uigridlayout(app.Grid);
            app.ToolsGridLayout.ColumnWidth = {'1x'};
            app.ToolsGridLayout.RowHeight = {25, 'fit', 'fit', 'fit'};
            app.ToolsGridLayout.Padding = [0 0 0 0];
            app.ToolsGridLayout.Layout.Row = [1 2];
            app.ToolsGridLayout.Layout.Column = 2;
            app.ToolsGridLayout.BackgroundColor = [0.149 0.149 0.149];

            % Create ShapesPanel
            app.ShapesPanel = uipanel(app.ToolsGridLayout);
            app.ShapesPanel.ForegroundColor = [0.9412 0.9412 0.9412];
            app.ShapesPanel.Title = 'Shapes';
            app.ShapesPanel.BackgroundColor = [0.149 0.149 0.149];
            app.ShapesPanel.Layout.Row = 3;
            app.ShapesPanel.Layout.Column = 1;
            app.ShapesPanel.FontWeight = 'bold';
            app.ShapesPanel.FontSize = 14;

            % Create ShapesGridLayout
            app.ShapesGridLayout = uigridlayout(app.ShapesPanel);
            app.ShapesGridLayout.ColumnWidth = {'1x'};
            app.ShapesGridLayout.RowHeight = {40, 40, 40, 40};
            app.ShapesGridLayout.ColumnSpacing = 2;
            app.ShapesGridLayout.RowSpacing = 2;
            app.ShapesGridLayout.Padding = [2 2 2 2];
            app.ShapesGridLayout.BackgroundColor = [0.149 0.149 0.149];

            % Create PointsButton
            app.PointsButton = uibutton(app.ShapesGridLayout, 'state');
            app.PointsButton.ValueChangedFcn = createCallbackFcn(app, @PointsButtonValueChanged, true);
            app.PointsButton.Icon = 'points_32.png';
            app.PointsButton.Text = 'Points';
            app.PointsButton.BackgroundColor = [0.651 0.651 0.651];
            app.PointsButton.FontColor = [1 1 1];
            app.PointsButton.Layout.Row = 1;
            app.PointsButton.Layout.Column = 1;

            % Create PolygonButton
            app.PolygonButton = uibutton(app.ShapesGridLayout, 'state');
            app.PolygonButton.ValueChangedFcn = createCallbackFcn(app, @PolygonButtonValueChanged, true);
            app.PolygonButton.Icon = 'patch_32.png';
            app.PolygonButton.Text = 'Polygon';
            app.PolygonButton.BackgroundColor = [0.651 0.651 0.651];
            app.PolygonButton.FontColor = [1 1 1];
            app.PolygonButton.Layout.Row = 3;
            app.PolygonButton.Layout.Column = 1;

            % Create PlaneButton
            app.PlaneButton = uibutton(app.ShapesGridLayout, 'state');
            app.PlaneButton.ValueChangedFcn = createCallbackFcn(app, @PlaneButtonValueChanged, true);
            app.PlaneButton.Icon = 'plane_32.png';
            app.PlaneButton.Text = 'Plane';
            app.PlaneButton.BackgroundColor = [0.651 0.651 0.651];
            app.PlaneButton.FontColor = [1 1 1];
            app.PlaneButton.Layout.Row = 4;
            app.PlaneButton.Layout.Column = 1;

            % Create LineButton
            app.LineButton = uibutton(app.ShapesGridLayout, 'state');
            app.LineButton.ValueChangedFcn = createCallbackFcn(app, @LineButtonValueChanged, true);
            app.LineButton.Icon = 'line_32.png';
            app.LineButton.Text = 'Line';
            app.LineButton.BackgroundColor = [0.651 0.651 0.651];
            app.LineButton.FontColor = [1 1 1];
            app.LineButton.Layout.Row = 2;
            app.LineButton.Layout.Column = 1;

            % Create EditPanel
            app.EditPanel = uipanel(app.ToolsGridLayout);
            app.EditPanel.ForegroundColor = [0.902 0.902 0.902];
            app.EditPanel.Title = 'Edit';
            app.EditPanel.BackgroundColor = [0.149 0.149 0.149];
            app.EditPanel.Layout.Row = 2;
            app.EditPanel.Layout.Column = 1;
            app.EditPanel.FontWeight = 'bold';
            app.EditPanel.FontSize = 14;

            % Create EditGridLayout
            app.EditGridLayout = uigridlayout(app.EditPanel);
            app.EditGridLayout.ColumnWidth = {'1x'};
            app.EditGridLayout.RowHeight = {40, 40, 40, 40, 40};
            app.EditGridLayout.ColumnSpacing = 2;
            app.EditGridLayout.RowSpacing = 2;
            app.EditGridLayout.Padding = [2 2 2 2];
            app.EditGridLayout.BackgroundColor = [0.149 0.149 0.149];

            % Create SelectButton
            app.SelectButton = uibutton(app.EditGridLayout, 'state');
            app.SelectButton.ValueChangedFcn = createCallbackFcn(app, @SelectButtonValueChanged, true);
            app.SelectButton.Icon = 'cursor_32.png';
            app.SelectButton.Text = 'Select';
            app.SelectButton.BackgroundColor = [0.651 0.651 0.651];
            app.SelectButton.FontColor = [1 1 1];
            app.SelectButton.Layout.Row = 1;
            app.SelectButton.Layout.Column = 1;

            % Create EditButton
            app.EditButton = uibutton(app.EditGridLayout, 'push');
            app.EditButton.ButtonPushedFcn = createCallbackFcn(app, @EditButtonPushed, true);
            app.EditButton.Icon = 'edit_24.png';
            app.EditButton.WordWrap = 'on';
            app.EditButton.BackgroundColor = [0.651 0.651 0.651];
            app.EditButton.FontColor = [1 1 1];
            app.EditButton.Tooltip = {''};
            app.EditButton.Layout.Row = 2;
            app.EditButton.Layout.Column = 1;
            app.EditButton.Text = 'Edit';

            % Create DeleteButton
            app.DeleteButton = uibutton(app.EditGridLayout, 'push');
            app.DeleteButton.ButtonPushedFcn = createCallbackFcn(app, @DeleteButtonPushed, true);
            app.DeleteButton.Icon = 'delete_24.png';
            app.DeleteButton.WordWrap = 'on';
            app.DeleteButton.BackgroundColor = [0.651 0.651 0.651];
            app.DeleteButton.FontColor = [1 1 1];
            app.DeleteButton.Tooltip = {''};
            app.DeleteButton.Layout.Row = 3;
            app.DeleteButton.Layout.Column = 1;
            app.DeleteButton.Text = 'Delete';

            % Create FinishButton
            app.FinishButton = uibutton(app.EditGridLayout, 'push');
            app.FinishButton.ButtonPushedFcn = createCallbackFcn(app, @FinishButtonPushed, true);
            app.FinishButton.Icon = 'check_24.png';
            app.FinishButton.WordWrap = 'on';
            app.FinishButton.BackgroundColor = [0.651 0.651 0.651];
            app.FinishButton.FontColor = [1 1 1];
            app.FinishButton.Tooltip = {''};
            app.FinishButton.Layout.Row = 4;
            app.FinishButton.Layout.Column = 1;
            app.FinishButton.Text = 'Finish';

            % Create ColorGridLayout
            app.ColorGridLayout = uigridlayout(app.EditGridLayout);
            app.ColorGridLayout.RowHeight = {'1x'};
            app.ColorGridLayout.ColumnSpacing = 5;
            app.ColorGridLayout.RowSpacing = 5;
            app.ColorGridLayout.Padding = [0 0 0 0];
            app.ColorGridLayout.Layout.Row = 5;
            app.ColorGridLayout.Layout.Column = 1;
            app.ColorGridLayout.BackgroundColor = [0.149 0.149 0.149];

            % Create ColorSelector
            app.ColorSelector = wt.ColorSelector(app.ColorGridLayout);
            app.ColorSelector.ShowEditField = 'off';
            app.ColorSelector.ValueChangedFcn = createCallbackFcn(app, @ColorSelectorValueChanged, true);
            app.ColorSelector.BackgroundColor = [0.149 0.149 0.149];
            app.ColorSelector.Layout.Row = 1;
            app.ColorSelector.Layout.Column = 1;

            % Create ColorLabel
            app.ColorLabel = uilabel(app.ColorGridLayout);
            app.ColorLabel.FontColor = [0.9412 0.9412 0.9412];
            app.ColorLabel.Layout.Row = 1;
            app.ColorLabel.Layout.Column = 2;
            app.ColorLabel.Text = 'Color';

            % Create ControlsButton
            app.ControlsButton = uibutton(app.ToolsGridLayout, 'push');
            app.ControlsButton.ButtonPushedFcn = createCallbackFcn(app, @ControlsButtonPushed, true);
            app.ControlsButton.Icon = 'help_24.png';
            app.ControlsButton.BackgroundColor = [0.651 0.651 0.651];
            app.ControlsButton.FontColor = [1 1 1];
            app.ControlsButton.Layout.Row = 1;
            app.ControlsButton.Layout.Column = 1;
            app.ControlsButton.Text = 'Controls';

            % Create AnnotationLabelsPanel
            app.AnnotationLabelsPanel = uipanel(app.Grid);
            app.AnnotationLabelsPanel.ForegroundColor = [0.9412 0.9412 0.9412];
            app.AnnotationLabelsPanel.Title = 'Annotation Labels';
            app.AnnotationLabelsPanel.BackgroundColor = [0.149 0.149 0.149];
            app.AnnotationLabelsPanel.Layout.Row = 2;
            app.AnnotationLabelsPanel.Layout.Column = 3;
            app.AnnotationLabelsPanel.FontWeight = 'bold';
            app.AnnotationLabelsPanel.FontSize = 14;

            % Create AnnotationLabelsGridLayout
            app.AnnotationLabelsGridLayout = uigridlayout(app.AnnotationLabelsPanel);
            app.AnnotationLabelsGridLayout.ColumnWidth = {'1x'};
            app.AnnotationLabelsGridLayout.RowHeight = {'1x'};
            app.AnnotationLabelsGridLayout.Padding = [0 0 0 0];

            % Create AnnotationList
            app.AnnotationList = wt.AnnotationLabelsList(app.AnnotationLabelsGridLayout);
            app.AnnotationList.SelectionChangedFcn = createCallbackFcn(app, @AnnotationListSelectionChanged, true);
            app.AnnotationList.BackgroundColor = [0.149 0.149 0.149];
            app.AnnotationList.Layout.Row = 1;
            app.AnnotationList.Layout.Column = 1;

            % Create FileGridLayout
            app.FileGridLayout = uigridlayout(app.Grid);
            app.FileGridLayout.ColumnWidth = {'1x'};
            app.FileGridLayout.RowHeight = {'1x', '1x', '1x'};
            app.FileGridLayout.Padding = [5 5 5 5];
            app.FileGridLayout.Layout.Row = 1;
            app.FileGridLayout.Layout.Column = 3;
            app.FileGridLayout.BackgroundColor = [0.149 0.149 0.149];

            % Create LoadButton
            app.LoadButton = uibutton(app.FileGridLayout, 'push');
            app.LoadButton.ButtonPushedFcn = createCallbackFcn(app, @LoadButtonPushed, true);
            app.LoadButton.Icon = 'folder_file_open_24.png';
            app.LoadButton.WordWrap = 'on';
            app.LoadButton.BackgroundColor = [0.149 0.149 0.149];
            app.LoadButton.FontSize = 14;
            app.LoadButton.FontColor = [0.9412 0.9412 0.9412];
            app.LoadButton.Tooltip = {''};
            app.LoadButton.Layout.Row = 1;
            app.LoadButton.Layout.Column = 1;
            app.LoadButton.Text = 'Load DICOM Image';

            % Create ExportButton
            app.ExportButton = uibutton(app.FileGridLayout, 'push');
            app.ExportButton.ButtonPushedFcn = createCallbackFcn(app, @ExportButtonPushed, true);
            app.ExportButton.Icon = 'export_24.png';
            app.ExportButton.WordWrap = 'on';
            app.ExportButton.BackgroundColor = [0.149 0.149 0.149];
            app.ExportButton.FontSize = 14;
            app.ExportButton.FontColor = [0.9412 0.9412 0.9412];
            app.ExportButton.Tooltip = {''};
            app.ExportButton.Layout.Row = 2;
            app.ExportButton.Layout.Column = 1;
            app.ExportButton.Text = 'Export Labels';

            % Create ImportButton
            app.ImportButton = uibutton(app.FileGridLayout, 'push');
            app.ImportButton.ButtonPushedFcn = createCallbackFcn(app, @ImportButtonPushed, true);
            app.ImportButton.Icon = 'import_24.png';
            app.ImportButton.WordWrap = 'on';
            app.ImportButton.BackgroundColor = [0.149 0.149 0.149];
            app.ImportButton.FontSize = 14;
            app.ImportButton.FontColor = [0.9412 0.9412 0.9412];
            app.ImportButton.Tooltip = {''};
            app.ImportButton.Layout.Row = 3;
            app.ImportButton.Layout.Column = 1;
            app.ImportButton.Text = 'Import Labels';

        end
    end

end