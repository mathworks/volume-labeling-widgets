classdef BaseAnnotationApp < wt.apps.BaseApp & wt.mixin.FontColorable
    % Base application class for annotating a volume or isosurface on axes
    
    % Copyright 2020 The MathWorks, Inc.
    
    
    %% Properties
    properties (Abstract, AbortSet)
        AnnotationModel (1,:) wt.model.BaseAnnotationModel %Annotations
    end
    
    properties (Dependent)
        
        % Color of new or selected annotation
        AnnotationColor
        
        % Show or hide the axes, ticks, etc.
        ShowAxes (1,1) logical 
        
        % Show or hide the grid
        ShowGrid (1,1) logical
        
    end
        
    
    
    %% Internal Properties
    properties (Dependent, SetAccess = private)
        
        % Selected tool
        CurrentTool (1,:) wt.tool.BaseAnnotationTool
        
        IsAddingInteractiveAnnotation
        PendingAnnotationModel (1,:)
        SelectedAnnotationModel (1,:)
    end
    
    
    properties (Transient, SetAccess = protected)
        
        Toolbar wt.apps.components.AnnotationToolbar
        
        AnnotationViewer (1,:) = gobjects(1,0)
        AnnotationTable = gobjects(1,0)
        
        SelectButton (1,:) = gobjects(1,0)
        EditButton (1,:) = gobjects(1,0)
        DeleteButton (1,:) = gobjects(1,0)
        FinishButton (1,:) = gobjects(1,0)
        ColorSelector (1,:) = gobjects(1,0)
        MaskInvertButton (1,:) = gobjects(1,0)
        MaskEraseButton (1,:) = gobjects(1,0)
        MaskBrushSizeSlider (1,:) = gobjects(1,0)
        LastPath (1,1) string = pwd
        
    end %properties
    
    
    properties (Transient, Hidden, SetAccess = protected)
        
        FileToolbar
        
        
%         AnnotationStartedListener event.listener % Listener to AnnotatedVolumeViewer changes
%         AnnotationStoppedListener event.listener % Listener to AnnotatedVolumeViewer changes
%         AnnotationSelectedListener event.listener % Listener to AnnotatedVolumeViewer changes
%         AnnotationModelChangedListener event.listener % Listener to AnnotationModel changes
        AnnotationChangedListener event.listener % Listeners to Annotation changes

        
    end %properties
    
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function setup(app)
            
            % Adjust defaults
            standardBackground = [1 1 1] * 0.8;
            app.Figure.Color = standardBackground;
            app.Grid.BackgroundColor = standardBackground;
            app.Grid.ColumnWidth = {'1x',263};
            app.Grid.RowHeight = {100,'1x'};
            app.Position(3:4) = [1000 800];
            
            % Annotation Toolbar
            app.Toolbar = wt.apps.components.AnnotationToolbar(app.Grid);
            app.Toolbar.Layout.Column = [1 2];
            app.Toolbar.Layout.Row = 1;
            app.Toolbar.FontColor = [0 0 0];
            app.Toolbar.Toolbar.TitleColor = [1 1 1] * 0.5;
            app.Toolbar.BackgroundColor = standardBackground;
            
            % Toolbar callbacks
            app.Toolbar.FileSection.ButtonPushedFcn = @(h,e)onFileToolbarButton(app,e);
            app.Toolbar.EditSection.ButtonPushedFcn = @(h,e)onEditToolbarButton(app,e);
            app.Toolbar.ColorSelector.ValueChangedFcn = @(h,e)onColorChanged(app,e);
            app.Toolbar.ShapesSection.ButtonPushedFcn = @(h,e)onShapesToolbarButton(app,e);
            app.Toolbar.MaskSection.ButtonPushedFcn = @(h,e)onMaskToolbarButton(app,e);
            app.Toolbar.MaskBrushSizeSlider.ValueChangedFcn = @(h,e)onBrushChanged(app,e);
            app.Toolbar.HelpAddButton.ButtonPushedFcn = @(h,e)onHelpButton(app);

            % Annotation Table
            app.AnnotationTable = uitable(app.Grid);
            app.AnnotationTable.Layout.Column = 2;
            app.AnnotationTable.Layout.Row = 2;
            app.AnnotationTable.ColumnName = ["","Type","Name"];
            app.AnnotationTable.ColumnEditable = [true false true];
            app.AnnotationTable.ColumnFormat = {'logical','char','char'};
            app.AnnotationTable.ColumnWidth = {25,80,100};
            app.AnnotationTable.SelectionType = 'row';
            app.AnnotationTable.Multiselect = true;
            app.AnnotationTable.CellEditCallback = @(h,e)onTableChanged(app,e);
            app.AnnotationTable.CellSelectionCallback = @(h,e)onTableSelectionChanged(app,e);
            
        end %function
        
        
        
        function update(app)
            
            % Update the annotation table
            aObj = app.AnnotationModel;
            if isempty(aObj)
                aDataCell = cell(0,3);
            else
                aDataCell = horzcat(...
                    {aObj.IsVisible}',...
                    regexprep({aObj.Type},'(.+\.)|Annotation','')',...
                    cellstr([aObj.Name]') );
            end
            app.AnnotationTable.Data = aDataCell;
            
            % Color table rows based on annotation color
            app.AnnotationTable.removeStyle();
            for idx = 1:numel(aObj)
                app.AnnotationTable.addStyle(...
                    uistyle('BackgroundColor',aObj(idx).Color),...
                    'row',idx)
            end
            
            % Update table selection
            if isempty(app.SelectedAnnotationModel)
                idxSelRow = [];
            else
                idxSelRow = find(app.SelectedAnnotationModel == app.AnnotationModel);
                
                % Bold the selected annotation
                app.AnnotationTable.addStyle(...
                    uistyle('FontWeight','bold'),...
                    'row',idxSelRow);
            end
            app.AnnotationTable.Selection = idxSelRow;
            
            
            % Get the selected tool
            selTool = app.CurrentTool;
            
            % Update the toolbar mode
            if isempty(selTool)
                app.Toolbar.Mode = "";
            elseif isa(selTool,'wt.tool.Select')
                app.Toolbar.Mode = "Select";
            else
                aObj = selTool.AnnotationModel;
                currentMode = regexp(aObj.Type,'.(\w+)Annotation$','tokens','once');
                app.Toolbar.Mode = string(currentMode);
                if isprop(selTool,'Erase')
                   app.Toolbar.MaskEraseOn = selTool.Erase;
                end
                if isprop(selTool,'BrushSize')
                   app.Toolbar.BrushSize = selTool.BrushSize;
                end
            end
            
            % Update the toolbar states
            app.Toolbar.AnnotationIsSelected = ~isempty(app.SelectedAnnotationModel);
            app.Toolbar.AnnotationIsBeingEdited = app.IsAddingInteractiveAnnotation;
            if isscalar(app.SelectedAnnotationModel)
                app.Toolbar.Color = app.SelectedAnnotationModel.Color;
            end

        end %function
        
        
        function onColorChanged(app,e)
            
            % Get the new color
            newColor = e.Value;
            
            % Update the selected annotation
            aObj = app.SelectedAnnotationModel;
            if ~isempty(aObj)
                set(aObj,'Color',newColor);
            end
            
            % Update the view
            app.update();
            
        end %function
        
        
        function onBrushChanged(app,e)
            
            % Find the brush
            selTool = app.CurrentTool;
            if isscalar(selTool) && isa(selTool,'wt.tool.Brush')
                newSize = max(ceil(e.Value),1);
                % Must be odd number
                if newSize > 3 && ~mod(newSize,2)
                    newSize = newSize + 1;
                end
                selTool.BrushSize = newSize;
            end
            
            app.update();
            
        end %function
        
        
        function attachAnnotationViewerListeners(app)
            % Attach listeners
            
            v = app.AnnotationViewer;
            fcn = @(h,e)onAnnotationChanged(app,e);
            app.AnnotationChangedListener = [
                event.listener(v,"AnnotationSelected",fcn)
                event.listener(v,"AnnotationChanged",fcn)
                event.listener(v,"AnnotationModelChanged",fcn)
                ];
            % event.listener(v,"AnnotationStarted",fcn)
            % event.listener(v,"AnnotationStopped",fcn)
            
        end %function
        
        
        function onAnnotationChanged(app,evt)
            
            if app.SetupComplete
                app.update();
            end
            
        end %function
        
        
        function onTableChanged(app,e)
            
            % What was changed?
            newValue = e.NewData;
            rIdx = e.Indices(1);
            cIdx = e.Indices(2);
            
            % Update the model, depending on which column
            switch cIdx
                case 1
                    app.AnnotationModel(rIdx).IsVisible = newValue;
                case 3
                    app.AnnotationModel(rIdx).Name = newValue;
            end %switch
            
        end %function
        
        
        function onTableSelectionChanged(app,e)
            
            % Ignore if no indices
            if ~isempty(e.Indices)
                
                % Get the selection
                selRow = e.Indices(1,1);
                aObj = app.AnnotationModel(selRow);
                
                % Toggle selection
                if all(aObj.IsSelected)
                    % Deselect it
                    app.AnnotationViewer.selectAnnotation(aObj([]));
                else
                    % Select it in the annotation viewer
                    app.AnnotationViewer.selectAnnotation(aObj);
                end
                
            end %% Ignore if no indices
            
        end %function
        
        
        
        function onFileToolbarButton(app,e)

            % Which button?
            switch e.Button
                
                case app.Toolbar.ExportButton
                    
                    message = 'Export Annotations';
                    pattern = {'*.mat','MATLAB MAT-file'};
                    startPath = fullfile(app.LastPath, 'Annotations.mat');
                    [fileName,pathName] = uiputfile(pattern,message,startPath);
                    if ~isequal(fileName,0)
                        app.LastPath = pathName;
                        filePath = fullfile(pathName,fileName);
                        aObj = app.AnnotationModel;
                        save(filePath,'aObj');
                    end
                    
                case app.Toolbar.ImportButton
            
                    
                    message = 'Import Annotations';
                    pattern = {'*.mat','MATLAB MAT-file'};
                    [fileName,pathName] = uigetfile(pattern,message,app.LastPath);
                    if ~isequal(fileName,0)
                        app.LastPath = pathName;
                        filePath = fullfile(pathName,fileName);
                        s = load(filePath);
                        if isfield(s,'aObj') && isa(s.aObj,'wt.model.BaseAnnotationModel')
                            app.AnnotationViewer.removeAnnotation(app.AnnotationModel);
                            app.AnnotationViewer.addAnnotation(s.aObj);
                        else
                            dlg = errordlg('Not a valid annotation file.');
                            uiwait(dlg);
                        end
                    end
                    
            end %switch e.Button
            
            app.update();
            
        end %function
        
        
        function onEditToolbarButton(app,e)
            
            % Which button?
            switch e.Button
                
                case app.Toolbar.SelectButton
                    
                    % Is select already on?
                    selTool = app.CurrentTool;
                    if isscalar(selTool) && isa(selTool,'wt.tool.Select') && selTool.IsStarted
                        selTool.stop();
                    else
                        app.AnnotationViewer.launchSelectTool();
                    end
                    
                case app.Toolbar.EditButton
                    
                    if isempty(app.SelectedAnnotationModel)
                        app.update();
                    else
                        app.AnnotationViewer.launchEditingTool(app.SelectedAnnotationModel,false);
                    end
                    
                case app.Toolbar.DeleteButton
                    
                    if isempty(app.SelectedAnnotationModel)
                        app.update();
                    else
                        app.AnnotationViewer.removeAnnotation(app.SelectedAnnotationModel);
                    end
                    
                case app.Toolbar.FinishButton
                    
                    app.AnnotationViewer.finishAnnotation();
                    
            end %switch e.Button
            
        end %function
        
        
        function onShapesToolbarButton(app,e)
            
            % Make a new annotation name
            existingNames = vertcat(app.AnnotationModel.Name);
            newName = matlab.lang.makeUniqueStrings("New Annotation",existingNames);
            
            % Which button?
            switch e.Button
                    
                case app.Toolbar.PointsButton
                    a = wt.model.PointsAnnotation(...
                        'Name',newName,...
                        'Color',app.AnnotationColor);
                    app.AnnotationViewer.addInteractiveAnnotation(a);
                    
                case app.Toolbar.LineButton
                    a = wt.model.LineAnnotation(...
                        'Name',newName,...
                        'Color',app.AnnotationColor);
                    app.AnnotationViewer.addInteractiveAnnotation(a);
                    
                case app.Toolbar.PolygonButton
                    a = wt.model.PolygonAnnotation(...
                        'Name',newName,...
                        'Color',app.AnnotationColor,...
                        'Alpha',0.5);
                    app.AnnotationViewer.addInteractiveAnnotation(a);
                    
                case app.Toolbar.PlaneButton
                    a = wt.model.PlaneAnnotation(...
                        'Name',newName,...
                        'Color',app.AnnotationColor,...
                        'Alpha',0.5);
                    app.AnnotationViewer.addInteractiveAnnotation(a);
                    
            end %switch e.Button
            
        end %function
        
        
        function onMaskToolbarButton(app,e)
            
            % Get selected tool
            selTool = app.CurrentTool;
            
            % Which button?
            switch e.Button
                
                case app.Toolbar.MaskEraseButton
                    if isscalar(selTool) && isa(selTool,'wt.tool.Brush')
                        selTool.Erase = ~selTool.Erase;
                    end
                    
                case app.Toolbar.MaskInvertButton
                    if isscalar(selTool) && isa(selTool,'wt.tool.Brush')
                        % slice = repmat({':'},1,3);
                        % idxSliceDim = app.AnnotationViewer.h.MainView.SliceDimension;
                        % slice{idxSliceDim} = app.AnnotationViewer.h.MainView.Slice;
                        % selTool.invert(slice);
                        selTool.invert();
                    end
                    
            end %switch e.Button
            
            app.update();
            
        end %function
        
        
        
        function onHelpButton(app)
            
            title = "Annotation Tools";
            message = [
                "Adding/Edit Point-based Annotations:"
                "Left-click adds points or draws."
                "Right-click drag moves an existing point."
                "Middle-click or Shift+click deletes a point."
                "Double-click finishes"
                ""
                "Adding/Edit Brush-based Annotations:"
                "Left button draws."
                "Right button erases."
                "Double-click finishes"
                ];
            
            % Create an error dialog
            uialert(app.Figure,message,title,'Icon','info');
            
        end %function
        
    end %methods
    
    
    %% Get/Set Methods
    methods
        
        function value = get.CurrentTool(app)
            value = app.AnnotationViewer.CurrentTool;
        end
        
        function value = get.IsAddingInteractiveAnnotation(app)
            value = app.AnnotationViewer.IsAddingInteractiveAnnotation;
        end
        
        function value = get.PendingAnnotationModel(app)
            value = app.AnnotationViewer.PendingAnnotationModel;
        end
        
        function value = get.SelectedAnnotationModel(app)
            value = app.AnnotationViewer.SelectedAnnotationModel;
        end
        
        function value = get.AnnotationColor(app)
            value = app.Toolbar.Color;
        end
        
        function set.AnnotationColor(app,value)
            app.Toolbar.Color = value;
        end
        
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
        
        function set.AnnotationViewer(app,value)
            app.AnnotationViewer = value;
            app.attachAnnotationViewerListeners();
        end
        
    end %methods
    
end %classdef