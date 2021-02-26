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

            % Customize the app name and icon
            app.Name = 'Isosurface Labeling - Example Hand-Coded MATLAB App';
            app.Figure.Icon = 'volume_labeling_toolbox_icon.png';

            % Create AnnotationViewer
            app.AnnotationViewer = wt.IsosurfaceLabeler(app.Grid);
            app.AnnotationViewer.Layout.Row = [1 2];
            app.AnnotationViewer.Layout.Column = 1;

            % Call superclass method
            app.setup@handCode.BaseLabelingApp();

            % Update the load button text
            app.LoadButton.Text = "Load Isosurface";

        end %function


        % Button pushed function: LoadButton
        function LoadButtonPushed(app, ~)

            % Select a workspace variable with 3+ dims
            prompt = "Select a file containing a variable named 'data' containing a 3d matrix.";
            fileName = uigetfile(app.LastPath, prompt);

            % Return now if the user cancelled
            if isequal(fileName,0)
                return
            end

            % Trap errors
            try
                % Keep track of the last directory used
                pathName = fileparts(fileName);
                app.LastPath = pathName;

                % Load the file
                s = load(fileName,"-mat","data");

                % Prepare the isosurface
                assert(ndims(s.data) == 3);
                isovalue = 40;
                [faces, vertices] = isosurface(s.data, isovalue);
                voxel_size  = [1 1 3];
                vertices    = vertices .* voxel_size;
                vertexNormals = isonormals(s.data, vertices);

                % Create the model
                isoModel = wt.model.IsosurfaceModel(...
                    'Faces',faces,...
                    'Vertices',vertices,...
                    'VertexNormals',vertexNormals);

                % Store the new isosurface
                app.IsosurfaceModel = isoModel;

            catch

                % Send error to a dialog
                dlg = errordlg("Not a valid isosurface file. " + prompt);
                uiwait(dlg);

            end

            % Update the display
            app.update();

        end %function

    end %methods


    % Get/Set methods
    methods

        function value = get.IsosurfaceModel(app)
            value = app.AnnotationViewer.IsosurfaceModel;
        end

        function set.IsosurfaceModel(app, value)
            if ~isequal(app.AnnotationViewer.IsosurfaceModel, value)
                app.deleteAllAnnotations();
                app.AnnotationViewer.IsosurfaceModel = value;
            end
        end

    end %methods

end %classdef