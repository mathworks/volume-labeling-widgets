classdef VolumeAnnotationApp < wt.apps.BaseAnnotationApp
    % App example for annotating a volume
    %
    % Syntax:
    %           app = wt.apps.VolumeAnnotationApp
    %           app = wt.apps.VolumeAnnotationApp('Property','Value',...)
    
    %   Copyright 2020 The MathWorks, Inc.
    
    
    %% Properties
    properties (AbortSet, Dependent)
        
        % Volume
        VolumeModel (1,1) wt.model.VolumeModel 
        
        % Annotations
        AnnotationModel  
    end
    
    
    
    %% Internal Properties
    properties (Access = private)
        
        % Listeners to mouse events
        MouseWheelListener event.listener
        
    end %properties
    
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function setup(app)
            
            % Set the name
            app.Name = "Volume Annotation & Labeling";
            
            % Call superclass method
            app.setup@wt.apps.BaseAnnotationApp();
            
            % Create the annotation viewer
            app.AnnotationViewer = wt.AnnotatedVolumeQuadViewer(app.Grid);
            app.AnnotationViewer.Layout.Column = 1;
            app.AnnotationViewer.Layout.Row = 2;
            app.AnnotationViewer.ShowAxes = true;
            
            % Place the annotation viewer in the grid
            app.AnnotationViewer.Parent = app.Grid;
            app.AnnotationViewer.Layout.Column = 1;
            app.AnnotationViewer.Layout.Row = 2;
            
            % Set default volume model
            app.VolumeModel = wt.model.VolumeModel;
            
            % Start listeners to window mouse events
            app.MouseWheelListener = event.listener(app.Figure,...
                'WindowScrollWheel',@(h,e)onMouseWheel_private(app,e));
            
        end %function
        
        
        
        function update(app)
                
            % Call superclass method
            app.update@wt.apps.BaseAnnotationApp();
            
        end %function
        
        
        % function configureToolbar(app)
        %
        %     % Disable Plane annotation
        %     app.Toolbar.PlaneButton.Enable = "off";
        %
        % end %function
        
        
        function onFileToolbarButton(app,e)
            % Handle button presses
            
            % Which button?
            switch e.Source
                
                case app.Toolbar.LoadButton
                    
                    message = 'Import DICOM Volume';
                    pathName = uigetdir(app.LastPath,message);
                    if ~isequal(pathName,0)
                        app.LastPath = pathName;
                        
                        try
                            volModel = wt.model.VolumeModel.fromDicomFile(pathName);
                            app.AnnotationViewer.removeAnnotation(app.AnnotationModel);
                            app.AnnotationViewer.VolumeModel = volModel;
                        catch err
                            dlg = errordlg(['Not a valid dicom volume. ' err.message]);
                            uiwait(dlg);
                        end
                        
                    end %if ~isequal(fileName,0)
                    
                otherwise
                    
                    % Call superclass method
                    app.onFileToolbarButton@wt.apps.BaseAnnotationApp(e);
                    
            end %switch e.Source
            
        end %function
        
        
        function onMaskToolbarButton(app,e)
            
            % Which button?
            switch e.Button
                
                case app.Toolbar.MaskAddButton
                    
                    a = wt.model.MaskAnnotation.fromVolumeModel(...
                        app.VolumeModel,...
                        'Color',app.AnnotationColor,...
                        'Alpha',0.5);
                    app.AnnotationViewer.addInteractiveAnnotation(a);
                    
                    app.update();
                    
                otherwise
                    
                    % Call superclass method
                    app.onMaskToolbarButton@wt.apps.BaseAnnotationApp(e);
                    
            end %switch e.Source
            
        end %function
        
    end %methods
    
    
    
    %% Private Methods
    methods (Access=private)
        
        function onMouseWheel_private(app,e)
            
            % Figure must be in pixels
            if ~strcmp(app.Figure.Units,'pixels')
                app.Figure.Units = 'pixels';
            end
            
            % Get mouse position within figure
            mousePos = app.Figure.CurrentPoint;
            
            % Get the scroll amount/direction
            scrollAmount = -e.VerticalScrollCount;
            
            % Get axes positions
            mainPos = getpixelposition(app.AnnotationViewer.Axes,true);
            sidePos = getpixelposition(app.AnnotationViewer.SideView.Axes,true);
            topPos = getpixelposition(app.AnnotationViewer.TopView.Axes,true);
            
            % Change slice
            if inBox(mainPos)
               app.AnnotationViewer.Slice = ...
                   max(1,app.AnnotationViewer.Slice + scrollAmount);
            elseif inBox(sidePos)
               app.AnnotationViewer.SideView.Slice = ...
                   max(1,app.AnnotationViewer.SideView.Slice + scrollAmount);
            elseif inBox(topPos)
               app.AnnotationViewer.TopView.Slice = ...
                   max(1,app.AnnotationViewer.TopView.Slice + scrollAmount);
            end

            % Helper function - detect if in the axes bounds
            function tf = inBox(boxPos)
                tf = mousePos(1) > boxPos(1) && ...
                    mousePos(1) < (boxPos(1) + boxPos(3)) && ...
                    mousePos(2) > boxPos(2) && ...
                    mousePos(2) < (boxPos(2) + boxPos(4));
            end
            
        end %function
        
    end %methods
    
    
    %% Get/Set Methods
    methods
        
        function value = get.VolumeModel(app)
            value = app.AnnotationViewer.VolumeModel;
        end
        
        function set.VolumeModel(app,value)
            app.AnnotationViewer.VolumeModel = value;
            if app.SetupComplete
                app.update();
            end
        end
        
        function value = get.AnnotationModel(app)
            value = app.AnnotationViewer.AnnotationModel;
        end
        
        function set.AnnotationModel(app,value)
            app.AnnotationModel = value;
            app.update();
        end
        
    end %methods
    
end %classdef