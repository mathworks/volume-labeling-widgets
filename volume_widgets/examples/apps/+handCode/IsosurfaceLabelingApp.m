classdef IsosurfaceLabelingApp < handCode.BaseLabelingApp
    % An isosurface annotation labeling example app using hand code
    %
    % This is intended as an example showing how to build a hand-coded app
    % using object-oriented programming.

    % Copyright 2020-2021 The MathWorks, Inc.


    %% Public properties
    properties (Dependent, Access = public)

        % The isosurface
        IsosurfaceModel (1,1) wt.model.IsosurfaceModel

    end %properties


    %% Protected methods
    methods (Access = protected)

        function setup(app)

            % Send app object to workspace (for debugging)
            assignin("base","app",app);

            % Customize the app name
            app.Name = 'Isosurface Labeling - Example MATLAB App';

            % Call superclass update
            app.setup@handCode.BaseLabelingApp();

            % Create AnnotationViewer
            app.AnnotationViewer = wt.IsosurfaceLabeler(app.Grid);
            app.AnnotationViewer.Layout.Row = [1 2];
            app.AnnotationViewer.Layout.Column = 1;

        end %function

    end %methods

end %classdef