classdef (Abstract) BaseIsosurfaceViewer < wt.abstract.BaseAxesViewer
    % Base class for Isosurface visualization on axes

    % Copyright 2018-2020 The MathWorks, Inc.


    %% Properties
    properties (AbortSet)

        % Data model for the isosurface's data
        IsosurfaceModel (1,:) wt.model.IsosurfaceModel

    end %properties


    %% Internal Properties
    properties (Transient, Access = private, UsedInUpdate = false)

        % Listener to IsosurfaceModel changes
        IsosurfaceModelChangedListener event.listener

    end %properties


    properties (Transient, Hidden, SetAccess = protected)

        % Lighting
        Light matlab.graphics.primitive.Light

    end %properties



    %% Setup
    methods (Access = protected)
        function setup(obj)

            % Load default volume model for demonstration
            obj.loadDefaultModel();

            % Call superclass setup
            obj.setup@wt.abstract.BaseAxesViewer();

            % Add lighting
            obj.addLighting();

            % Set initial listener
            obj.onModelSet();

        end %function
    end %methods



    %% Protected Methods
    methods (Access = protected)

        function loadDefaultModel(obj)
            % Populates the default volume model for demonstration

            % Load default volume data
            persistent faces vertices vertexNormals
            if isempty(faces)
                s = load('mri.mat');
                data = squeeze(s.D);
                isovalue = 40;
                [faces, vertices] = isosurface(data, isovalue);
                voxel_size  = [1 1 3];
                vertices    = vertices .* voxel_size;
                vertexNormals = isonormals(data,vertices);
            end

            % Create a default isosurface model
            isoModel = wt.model.IsosurfaceModel(...
                'Faces',faces,...
                'Vertices',vertices,...
                'VertexNormals',vertexNormals);

            % Store the result
            obj.IsosurfaceModel = isoModel;

        end %function


        function addLighting(obj)
            % Add lighting to the axes

            % Add lighting to upper front right
            lightColor = [.8 .7 .7];
            obj.Light(1) = light(...
                'Parent',obj.Axes,...
                'Style','infinite',...
                'Color',lightColor,...
                'Position',[1 -1 1]);

            % Add lighting to upper front left
            lightColor = [.8 .7 .7];
            obj.Light(end+1) = light(...
                'Parent',obj.Axes,...
                'Style','infinite',...
                'Color',lightColor,...
                'Position',[-1 -1 1]);

            % Add lighting to lower rear left
            lightColor = [.7 .4 .1];
            obj.Light(end+1) = light(...
                'Parent',obj.Axes,...
                'Style','infinite',...
                'Color',lightColor,...
                'Position',[-1 1 -1]);

            % Add lighting to lower rear right
            lightColor = [.7 .4 .1];
            obj.Light(end+1) = light(...
                'Parent',obj.Axes,...
                'Style','infinite',...
                'Color',lightColor,...
                'Position',[1 1 -1]);

        end %function


        function onModelChanged(obj,~)
            % Triggered on changes to the data in the model

            % Subclass may override this and choose to redraw based on the
            % event, if necessary for more complex scenarios.
            obj.requestUpdate();

        end %function

    end %methods


    %% Private Methods
    methods (Access = private)

        function onModelSet(obj)

            % Listen to changes in IsosurfaceModel
            obj.IsosurfaceModelChangedListener = event.listener(obj.IsosurfaceModel,...
                'PropertyChanged',@(h,e)onModelChanged(obj,e) );

        end %function

    end %methods


    %% Get/Set Methods
    methods

        function set.IsosurfaceModel(obj,value)

            % Update the value
            obj.IsosurfaceModel = value;

            % Update listener, etc.
            obj.onModelSet();

            % Workaround for g228243 (fixed in R2021a)
            if verLessThan('matlab','9.10')
                obj.requestUpdate();
            end %if

        end %function

    end %methods

end % classdef