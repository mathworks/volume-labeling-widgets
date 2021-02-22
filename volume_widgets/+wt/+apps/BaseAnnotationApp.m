classdef BaseAnnotationApp < wt.apps.BaseApp & wt.mixin.FontColorable
    % Base application class for annotating a volume or isosurface on axes
    % 
    % This is intended as an example and may be reworked in the future
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    
    %% Properties
    properties (Dependent, AbortSet)
        
        % Annotations
        AnnotationModel (1,:) wt.model.BaseAnnotationModel 
        
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
        
        AnnotationViewer wt.mixin.AnnotationViewer = wt.AnnotatedVolumeViewer.empty(0)
        AnnotationTable = gobjects(1,0)
        AnnotationList wt.apps.components.AnnotationList
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
    
    
    properties (Transient, NonCopyable, Access = protected)
        
        FileToolbar
        
        % Listeners to Annotation changes
        AnnotationChangedListener event.listener

        % When the selected annotation changes
        AnnotationSelectedListener event.listener
        
        % When the array of AnnotationModel has changed
        AnnotationModelChangedListener event.listener
        
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
            app.Toolbar.MaskBrushSizeSlider.ValueChangingFcn = @(h,e)onBrushChanged(app,e);
            app.Toolbar.HelpAddButton.ButtonPushedFcn = @(h,e)onHelpButton(app);

            app.AnnotationList = wt.apps.components.AnnotationList(app.Grid);
            app.AnnotationList.Layout.Column = 2;
            app.AnnotationList.Layout.Row = 2;
            app.AnnotationList.SelectionChangedFcn = @(h,e)onSelectionChanged(app,e);
        end %function
        
        
        
        function update(app)
            
            % Update the annotation table
            wt.utility.fastSet(app.AnnotationList, ...
                "AnnotationModel", app.AnnotationModel);
            
            % Toolbar mode?
            selTool = app.CurrentTool;
            if isempty(selTool)
                toolbarMode = "";
            elseif isa(selTool,'wt.tool.Select')
                toolbarMode = "Select";
            else
                currentMode = regexp(selTool.AnnotationModel.Type,...
                    '.(\w+)Annotation$','tokens','once');
                toolbarMode = string(currentMode);
            end
            
            % Anything selected?
            annIsSelected = ~isempty(app.SelectedAnnotationModel);
            
            % Erase mode?
            if isprop(selTool,"Erase")
                maskEraseOn = selTool.Erase;
            else
                maskEraseOn = false;
            end
            
            % Brush size?
            if isprop(selTool,"BrushSize")
                brushSize = selTool.BrushSize;
            else
                brushSize = 1;
            end
            
            % Color?
            if isscalar(app.SelectedAnnotationModel)
                wt.utility.fastSet(app.Toolbar, ...
                    "Color", app.SelectedAnnotationModel.Color);
            end
            
            
            % Update the toolbar states
            wt.utility.fastSet(app.Toolbar, ...
                "Mode", toolbarMode,...
                "MaskEraseOn", maskEraseOn,...
                "BrushSize", brushSize,...
                "AnnotationIsBeingEdited", app.IsAddingInteractiveAnnotation, ...
                "AnnotationIsSelected", annIsSelected);

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
            
            app.AnnotationSelectedListener = event.listener(...
                app.AnnotationViewer, "AnnotationSelected", ...
                @(h,e)onAnnotationSelected(app,e) );
            
            app.AnnotationModelChangedListener = event.listener(...
                app.AnnotationViewer, "AnnotationModelChanged", ...
                @(h,e)onAnnotationModelChanged(app,e) );
            
            app.AnnotationChangedListener = event.listener(...
                app.AnnotationViewer, "AnnotationChanged", ...
                @(h,e)onAnnotationChanged(app,e) );
            
            % app.AnnotationChangedListener = event.listener(...
            %     app.AnnotationViewer, "AnnotationStarted", ...
            %     @(h,e)onAnnotationModelStarted(app,e) );
            
            % app.AnnotationChangedListener = event.listener(...
            %     app.AnnotationViewer, "AnnotationStopped", ...
            %     @(h,e)onAnnotationStopped(app,e) );
            
        end %function
        
        
        function onAnnotationSelected(app,~)
            % When the selected annotation changes
            
            app.update();
            
        end %function
        
        
        function onAnnotationModelChanged(app,~)
            % When the array of AnnotationModel has changed
            
            app.update();
            
        end %function
        
        
        function onAnnotationChanged(app,evt)
            % When an annotation model has an internal change
            
            switch evt.Property
                
                case {
                        'IsSelected'
                        'IsBeingEdited'
                        'Color'
                        }
                    app.update();
                    
                otherwise
                    %Skip update
                    
            end %switch
            
        end %function
        
        
        function onSelectionChanged(app,evt)
            
            % Trigger selection in the viewer
            selIdx = evt.Value;
            aObjSel = app.AnnotationModel(selIdx);
            app.AnnotationViewer.selectAnnotation(aObjSel);
            
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
                    app.update();
                    
                case app.Toolbar.EditButton
                    
                    if ~isempty(app.SelectedAnnotationModel)
                        app.AnnotationViewer.launchEditingTool(app.SelectedAnnotationModel,false);
                    end
                    app.update();
                    
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
                "Left-click adds points."
                "Left-click and drag an existing point moves it."
                "Right-click an existing point deletes it."
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
        
        function value = get.AnnotationModel(app)
            if isempty(app.AnnotationViewer)
                value = wt.model.BaseAnnotationModel.empty(0);
            else
                value = app.AnnotationViewer.AnnotationModel;
            end
        end
        
        function set.AnnotationModel(app,value)
            app.AnnotationModel = value;
            if app.SetupComplete
                app.update();
            end
        end
        
    end %methods
    
end %classdef