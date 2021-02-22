classdef IsosurfaceAnnotationApp < wt.apps.BaseAnnotationApp
    %App example for annotating an isosurface
    %
    % Syntax:
    %           app = wt.app.IsosurfaceAnnotationApp
    %           app = wt.app.IsosurfaceAnnotationApp('Property','Value',...)
    % 
    % This is intended as an example and may be reworked in the future
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    
    %% Properties
    properties (Dependent)
        
       % Isosurface data model
       IsosurfaceModel (:,1) wt.model.IsosurfaceModel 
       
    end %properties
    
    
    %% Protected Methods
    methods (Access=protected)
    
        function setup(app)
            
            % Set the name
            app.Name = "Isosurface Annotation";
            
            % Call superclass method
            app.setup@wt.apps.BaseAnnotationApp();
            
            % Create the annotation viewer
            app.AnnotationViewer = wt.IsosurfaceLabeler(app.Grid);
            app.AnnotationViewer.Layout.Column = 1;
            app.AnnotationViewer.Layout.Row = 2;
            app.AnnotationViewer.ShowAxes = true;
            
            % Set default volume model
            app.IsosurfaceModel = wt.model.IsosurfaceModel;
        
            % Remove the Load Image button
            app.Toolbar.FileSection.Component(1) = [];
            
            % Remove the Mask section for isosurface
            app.Toolbar.Toolbar.Section(3) = [];
            
        end %function
        
        
        function update(app)
            
            % Call superclass method
            app.update@wt.apps.BaseAnnotationApp();
            
        end %function
        
    end %methods
    
    
    %% Get/Set Methods
    methods
        
        function value = get.IsosurfaceModel(app)
            value = app.AnnotationViewer.IsosurfaceModel;
        end
        
        function set.IsosurfaceModel(app,value)
            app.AnnotationViewer.IsosurfaceModel = value;
            if app.SetupComplete
                app.update();
            end
        end
        
    end %methods
    
end %classdef

