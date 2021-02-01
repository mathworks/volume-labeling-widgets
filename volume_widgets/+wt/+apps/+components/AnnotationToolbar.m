classdef AnnotationToolbar < wt.abstract.BaseWidget & wt.mixin.FontColorable
    % Common toolbar for annotation apps
    % 
    % This is intended as an example and may be reworked in the future
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    
    %% Properties
    properties (AbortSet)
        
        Mode (1,1) string = ""
        
        Color (1,3) double = [0 1 0]
        
        BrushSize (1,1) double {mustBePositive} = 1
        
        AnnotationIsSelected (1,1) logical = false
        
        AnnotationIsBeingEdited (1,1) logical = false
        
        MaskEraseOn (1,1) logical = false
        
    end %properties
    
    
    %% Internal Properties
    properties (Transient, SetAccess = private)
        
        % The top level toolbar
        Toolbar
        
        % File section
        FileSection
        LoadButton
        ImportButton
        ExportButton
        
        % Edit section
        EditSection
        SelectButton
        EditButton
        DeleteButton
        FinishButton
        ColorLabel
        ColorSelector
        
        % Shapes section
        ShapesSection
        PointsButton
        LineButton
        PolygonButton
        PlaneButton
        
        % Mask Section
        MaskSection
        MaskVerticalSection
        MaskAddButton
        MaskEraseButton
        MaskInvertButton
        MaskBrushSizeLabel
        MaskBrushSizeSlider
        
        % Help Section
        HelpSection
        HelpAddButton
        
        % Mode / State buttons
        StateButtons (:,1) = gobjects(0,1)
        
    end %properties
    
    
    
    %% Setup
    methods (Access = protected)
        function setup(obj)
            
            % Call superclass setup first
            obj.setup@wt.abstract.BaseWidget();
            
            
            % Create the toolbar
            obj.Toolbar = wt.Toolbar(obj.Grid);
            %obj.Toolbar.ButtonPushedFcn = @(h,e)fprintf("Toolbar Button Pressed: %s\n", e.ButtonText);
            
            % File section
            obj.FileSection = wt.toolbar.HorizontalSection();
            obj.FileSection.Title = "FILE";
            
            obj.LoadButton = obj.FileSection.addButton('folder_24.png','Load DICOM Image');
            obj.ImportButton = obj.FileSection.addButton('import_24.png','Import Labels');
            obj.ExportButton = obj.FileSection.addButton('export_24.png','Export Labels');
            
            % Edit section
            obj.EditSection = wt.toolbar.HorizontalSection();
            obj.EditSection.Title = "EDIT ANNOTATION";
            
            obj.SelectButton = obj.EditSection.addStateButton('cursor_32.png','Select Annotation');
            obj.EditButton = obj.EditSection.addButton('edit_24.png','Edit Selection');
            obj.EditSection.ComponentWidth(1:2) = [68 60];
            
            editVerticalSection = obj.EditSection.addVerticalSection();
            obj.DeleteButton = editVerticalSection.addButton('delete_24.png','Delete');
            obj.FinishButton = editVerticalSection.addButton('check_24.png','Finish');
            
            cpGrid = uigridlayout('Parent',[]);
            cpGrid.Padding = [0 0 0 0];
            cpGrid.RowHeight = {'1x'};
            cpGrid.ColumnWidth = {'1x','1x'};
            obj.ColorLabel = uilabel(cpGrid,'Text','Color:','HorizontalAlignment','right');
            obj.ColorSelector = wt.ColorSelector(cpGrid);
            obj.ColorSelector.ShowEditField = false;
            editVerticalSection.Component(end+1) = cpGrid;
            
            % Shapes section
            obj.ShapesSection = wt.toolbar.HorizontalSection();
            obj.ShapesSection.Title = "SHAPES";
            
            obj.PointsButton = obj.ShapesSection.addStateButton('points_32.png','Points');
            obj.LineButton = obj.ShapesSection.addStateButton('line_32.png','Line');
            obj.PolygonButton = obj.ShapesSection.addStateButton('patch_32.png','Polygon');
            obj.PlaneButton = obj.ShapesSection.addStateButton('plane_control_points_32.png','Plane');
            
            % Polygon button needs more width
            obj.ShapesSection.ComponentWidth(3) = 54;
            
            % Mask section
            obj.MaskSection = wt.toolbar.HorizontalSection();
            obj.MaskSection.Title = "3D MASK";
            
            obj.MaskAddButton = obj.MaskSection.addStateButton('brush_32.png','Mask');
            obj.MaskEraseButton = obj.MaskSection.addStateButton('erase_24.png','Erase');
            obj.MaskVerticalSection = obj.MaskSection.addVerticalSection();
            obj.MaskInvertButton = obj.MaskVerticalSection.addStateButton('invert_24.png','Invert');
            
            obj.MaskBrushSizeLabel = uilabel(cpGrid,'Text','Brush Size:','VerticalAlignment','bottom');
            obj.MaskBrushSizeSlider = uislider('Parent',[]);
            obj.MaskBrushSizeSlider.Limits = [1 49];
            obj.MaskBrushSizeSlider.MajorTicks = [];
            obj.MaskBrushSizeSlider.MinorTicks = [];
            obj.MaskVerticalSection.Component = [
                obj.MaskVerticalSection.Component
                obj.MaskBrushSizeLabel
                obj.MaskBrushSizeSlider
                ];
            
            
            % Help Section
            obj.HelpSection = wt.toolbar.HorizontalSection();
            obj.HelpSection.Title = "HELP";
            
            obj.HelpAddButton = obj.HelpSection.addButton('help_24.png','Mouse Controls');
            obj.HelpSection.ComponentWidth(1) = 60;
            
            
            obj.Toolbar.Section = [
                obj.FileSection
                obj.ShapesSection
                obj.MaskSection
                obj.EditSection
                obj.HelpSection
                ];
            
            % Track which buttons are states/modes
            obj.StateButtons = [
                obj.SelectButton
                obj.PointsButton
                obj.LineButton
                obj.PolygonButton
                obj.PlaneButton
                obj.MaskAddButton
                ];
            
            % Link styles
            obj.BackgroundColorableComponents = [...
                obj.Toolbar
                obj.ColorSelector
                ];
            obj.FontColorableComponents = [...
                obj.Toolbar
                obj.ColorLabel
                ];
            
        end %function
    end %methods
    
    
    
    %% Update
    methods (Access = protected)
        function update(obj)
            
            %disp('AnnotationToolbar update');
            
            % Update the current mode
            availableModes = string({obj.StateButtons.Text});
            isActive = contains(availableModes, obj.Mode) & strlength(obj.Mode);
            set(obj.StateButtons(~isActive),'Value',0)
            set(obj.StateButtons( isActive),'Value',1)
            
            % Check if brushing is active
            brushIsActive = obj.Mode == "Mask";
            
            % Update editing tool enables
            obj.EditButton.Enable = obj.AnnotationIsSelected && ...
                ~obj.AnnotationIsBeingEdited;
            obj.DeleteButton.Enable = obj.AnnotationIsSelected;
            obj.FinishButton.Enable = obj.AnnotationIsSelected && ...
                obj.AnnotationIsBeingEdited;
            obj.ColorLabel.Enable = obj.AnnotationIsSelected;
            obj.ColorSelector.Enable = obj.AnnotationIsSelected;
            obj.MaskEraseButton.Enable = brushIsActive;
            obj.MaskInvertButton.Enable = brushIsActive;
            obj.MaskBrushSizeLabel.Enable = brushIsActive;
            obj.MaskBrushSizeSlider.Enable = brushIsActive;
            
            % Update color
            obj.ColorSelector.Value = obj.Color;
            % if any(ismissing(obj.Color))
            %     obj.ColorSelector.Enable = "off";
            % else
            %     obj.ColorSelector.Value = obj.Color;
            %     obj.ColorSelector.Enable = "on";
            % end
            
            % Update brush tools
            obj.MaskBrushSizeSlider.Value = obj.BrushSize;
            obj.MaskEraseButton.Value = obj.MaskEraseOn;
            
            % Force height adjustments
            obj.MaskVerticalSection.Grid.RowHeight = {'1x','1x','1x'};
            
        end %function
    end %methods
    
    
end % classdef

