classdef (Abstract) BaseAxesViewer < wt.abstract.BaseWidget
    % Base class for visualizations containing an axes
    
    % Copyright 2018-2023 The MathWorks, Inc.
    
    
    %% Public Properties
    properties (Dependent, UsedInUpdate = false)
        
        % Show or hide the axes, ticks, etc.
        ShowAxes (1,1) matlab.lang.OnOffSwitchState = 'off'
        
        % Show or hide the grid
        ShowGrid (1,1) matlab.lang.OnOffSwitchState = 'off'
        
    end %properties
    
    
    
    %% Read-Only Properties
    properties (Dependent, SetAccess = protected)
        
        % Indicates if zoom is active
        ZoomActive (1,1) matlab.lang.OnOffSwitchState
    
    end %properties
    
    
    
    %% Internal Properties
    properties (Transient, Hidden, SetAccess = protected)
        
        % A container to manage placement for the axes
        AxesContainer
        
        % A tiledlayout to manage placement for the axes
        AxesLayout
        
        % The axes to display upon
        Axes matlab.graphics.axis.Axes
        
    end %properties
    
    
    
    %% Setup
    methods (Access = protected)
        function setup(obj)
            
            % Call superclass setup first to establish the grid
            obj.setup@wt.abstract.BaseWidget();     
            
            
            % Version dependency:
            if verLessThan("matlab","9.12")
                % Use a uigridlayout parent prior to R2022a

                % g2430389 Create intermediate layout for the tiledlayout
                obj.AxesContainer = uigridlayout(obj.Grid,[1 1]);
                obj.AxesContainer.Padding = [0 0 0 0];

            else
                % Use a panel parent starting in R2022a

                % g2613184 Can't parent a tiledlayout directly to a
                % uigridlayout anymore
                obj.AxesContainer = uipanel(obj.Grid);
                obj.AxesContainer.BorderType = 'none';

            end %if
            
            % g2430275 g2318236 Create a tiledlayout to properly size the axes
            obj.AxesLayout = tiledlayout(obj.AxesContainer,1,1);
            obj.AxesLayout.Padding = 'none';
            
            % Create the axes
            obj.Axes = axes(obj.AxesLayout);
            obj.Axes.XColor = [1 .4 .4];
            obj.Axes.YColor = [.4 .8 .4];
            obj.Axes.ZColor = [.5 .5 1];
            obj.Axes.Color = 'none';
            obj.Axes.XAxis.Label.String = 'X';
            obj.Axes.YAxis.Label.String = 'Y';
            obj.Axes.ZAxis.Label.String = 'Z';
            obj.Axes.GridColor = [1 1 1] * 0.8;
            obj.Axes.GridAlpha = 0.25;
            obj.Axes.DataAspectRatio = [1 1 1];
            obj.Axes.Layer = 'top'; %put grid above data
            obj.Axes.PickableParts = 'all';
            obj.Axes.Visible = 'off';
            %obj.Axes.ClippingStyle = "rectangle";
            obj.Axes.View = [-37.5 30];
            axis(obj.Axes,'tight');
            
            % Use grey colormap
            colormap(obj.Axes,gray(256))
            
            % No interactions by default - subclass to override
            disableDefaultInteractivity(obj.Axes);
            
            % Update the internal component lists
            obj.BackgroundColorableComponents = [obj.AxesContainer];
            
            % Change defaults
            obj.BackgroundColor = [1 1 1] * 0.15;
            
        end %function
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        function value = get.ShowAxes(obj)
            value = obj.Axes.Visible;
        end %function
        
        function set.ShowAxes(obj,value)
            obj.Axes.Visible = value;
            if value
                obj.AxesLayout.Padding = 'compact';
            else
                obj.AxesLayout.Padding = 'none';
            end
        end %function
        
        
        function value = get.ShowGrid(obj)
            value = obj.Axes.XGrid;
        end %function
        
        function set.ShowGrid(obj,value)
            grid(obj.Axes,value);
            if value
                obj.ShowAxes = true;
            end
        end %function
        
        
        function value = get.ZoomActive(obj)
            if isempty(obj.Axes.Toolbar) || isempty(obj.Axes.Toolbar.Children)
                value = false;
            else
                toolButtons = obj.Axes.Toolbar.Children;
                isZoomButton = contains({toolButtons.Tag},'zoom');
                value = any([toolButtons(isZoomButton).Value]);
            end
        end %function
        
    end %methods
    
end % classdef