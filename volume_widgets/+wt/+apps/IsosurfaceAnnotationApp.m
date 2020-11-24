classdef IsosurfaceAnnotationApp < wt.apps.BaseAnnotationApp
    %App example for annotating an isosurface
    %
    % Syntax:
    %           app = wt.app.IsosurfaceAnnotationApp
    %           app = wt.app.IsosurfaceAnnotationApp('Property','Value',...)
    
    %   Copyright 2020 The MathWorks, Inc.
    
    
    %% Properties
    properties (Dependent)
        
       % Isosurface  
       IsosurfaceModel (:,1) wt.model.IsosurfaceModel % Data model for the isosurface's data
       
       % Annotations 
       AnnotationModel
    end
    
    
    %% Internal Properties
    properties (Access = private)
        
        % Listeners to mouse events
        %MouseWheelListener event.listener
        
    end %properties
    
    
    %% Protected Methods
    methods (Access=protected)
    
        function setup(app)
            
            % Set the name
            app.Name = "Isosurface Annotation";
            
            % Call superclass method
            app.setup@wt.apps.BaseAnnotationApp();
            
            % Create the annotation viewer
            app.AnnotationViewer = wt.AnnotatedIsosurfaceViewer(app.Grid);
            app.AnnotationViewer.Layout.Column = 1;
            app.AnnotationViewer.Layout.Row = 2;
            app.AnnotationViewer.ShowAxes = true;
            
            % Set default volume model
            app.IsosurfaceModel = wt.model.IsosurfaceModel;
            
            % Configure toolbar appearance 
            app.configureToolbar()
            
        end %function
        
        
        function update(app)
            
            % Call superclass method
            app.update@wt.apps.BaseAnnotationApp();
            
        end %function
    
        
        function configureToolbar(app)
            app.Toolbar.LoadButton.Enable = "off";
            
            % Remove the Mask section for isosurface
            app.Toolbar.Toolbar.Section(4) = [];
            
        end %function
        
        
        function onFileToolbarButton(app,e)
            % Handle button presses
            
            % Which button?
            switch e.Source
                  
                otherwise
                    
                    % Call superclass method
                    app.onFileToolbarButton@wt.apps.BaseAnnotationApp(e);
                    
            end %switch e.Source
            
        end %function
        
        
        function onMaskToolbarButton(app,e)
            
            % Which button?
            switch e.Button
                                    
                otherwise
                    
                    % Call superclass method
                    app.onMaskToolbarButton@wt.apps.BaseAnnotationApp(e);
                    
            end %switch e.Source
            
        end %function
        
        
    end
    
    
    %% Private Methods
    methods (Access=private)
        
    end
    
    
    %% Get/Set Methods
    methods
        
        function value = get.IsosurfaceModel(app)
            value = app.AnnotationViewer.IsosufaceModel;
        end
        
        function set.IsosurfaceModel(app,value)
            app.AnnotationViewer.IsosurfaceModel = value;
            if app.SetupComplete
                app.update();
            end
        end
        
        function value = get.AnnotationModel(app)
            value = app.AnnotationViewer.AnnotationModel;
        end
        
        function set.AnnotationModel(app,value)
            app.AnnotationModel = value;
            if app.SetupComplete
                app.update();
            end
        end
        
        
    end
    
end %classdef

