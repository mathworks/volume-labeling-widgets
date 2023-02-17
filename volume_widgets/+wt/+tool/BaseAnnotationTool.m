classdef BaseAnnotationTool < handle & matlab.mixin.Heterogeneous
    % & wt.abstract.HandleClassBase
    % Base class for annotation tools

    % Copyright 2020-2023 The MathWorks, Inc.

    %% Events
    events
        AnnotationSelected
        AnnotationStarted
        AnnotationStopped
    end


    %% Abstract Properties
    properties (Abstract, SetAccess = protected)

        % Data model for the annotations
        AnnotationModel wt.model.BaseAnnotationModel

    end %properties


    %% Abstract Methods
    methods (Access = protected)

        % Triggered on mouse button down
        onMousePress(obj,evt)

    end %methods


    %% Properties
    properties (AbortSet)

        % Toggle erase mode - if true, tool is an eraser
        Erase (1,1) logical = false

    end %properties


    %% Internal Properties
    properties (SetAccess = private)

        % Monitored axes
        ClickableAxes matlab.graphics.axis.AbstractAxes

    end %properties

    properties (SetObservable, SetAccess = protected)

        % Current object the mouse is over
        CurrentHitObject matlab.graphics.Graphics

    end %properties

    properties (Access = protected)

        % Current figure
        CurrentFigure matlab.ui.Figure {mustBeScalarOrEmpty}

    end %properties

    properties (Access = private)

        % Listeners to mouse events
        MouseListeners event.listener

        % Track the last point for drag operation
        MouseLastDragPoint double = nan(1,3) % mouse press location

    end %properties

    properties (Dependent, SetAccess = private)

        % Returns the class name of the tool
        Type

        % Indicates whether the tool is running
        IsStarted

        % Indicates whether the tool is dragging the mouse
        IsDragging

    end %properties


    %% Sealed public methods (need for Heterogeneous arrays)
    methods (Sealed)

        function tf = eq(obj,varargin)
            tf = obj.eq@handle(varargin{:});
        end

        function tf = ne(obj,varargin)
            tf = obj.ne@handle(varargin{:});
        end

        function set(obj,varargin)
            obj.set@matlab.mixin.SetGet(varargin{:});
        end

        function value = get(obj,varargin)
            value = obj.get@matlab.mixin.SetGet(varargin{:});
        end

        function start(obj,annotation,axes)

            % Set properties
            if nargin >= 2
                obj.AnnotationModel = annotation;
            end
            if nargin >= 3
                obj.ClickableAxes = axes;
            end

            % Find the figure
            hFigure = ancestor(obj.ClickableAxes,'figure');
            if isempty(hFigure) || ~isvalid(hFigure)
                error('Tool requires axes plaxed in figure before start.');
            else
                obj.CurrentFigure = hFigure;
            end

            % Select tool is special case
            isSelectTool = isa(obj,'wt.tool.Select');

            % Toggle pickable parts of the annotation
            if isSelectTool
                % Some annotations (plane?) use Plot(2) also for selection
                set([obj.AnnotationModel.Plot],'PickableParts','visible');
            else
                % Only use Plot(1) for editing
                for idx = 1:numel(obj.AnnotationModel)
                    if ~isempty(obj.AnnotationModel(idx).Plot)
                        obj.AnnotationModel(idx).Plot(1).PickableParts = 'visible';
                    end
                end
            end

            % Mark annotation editing started
            set(obj.AnnotationModel,'IsBeingEdited',~isSelectTool);

            % Start the tool
            obj.onStart();

            % Start listeners to window mouse events
            obj.MouseListeners = [
                event.listener(obj.CurrentFigure,'WindowMousePress',@(h,e)onMousePress_private(obj,e))
                event.listener(obj.CurrentFigure,'WindowMouseRelease',@(h,e)onMouseRelease_private(obj,e))
                event.listener(obj.CurrentFigure,'WindowMouseMotion',@(h,e)onMouseMotion_private(obj,e))
                ];
            %event.listener(obj.CurrentFigure,'WindowScrollWheel',@(h,e)onMouseScroll_private(obj,e))

            % Notify listeners
            evt = wt.event.ToolInteractionData('AnnotationStarted',obj);
            obj.notify('AnnotationStarted',evt);

        end %function

        function stop(obj)
            for thisObj = obj(:)'
                if thisObj.IsStarted

                    % Stop the tool
                    thisObj.onStop();

                    % Restore the figure pointer
                    wt.utility.fastSet(thisObj.CurrentFigure,"Pointer","arrow");

                    % Clear mouse listeners and tracking items
                    thisObj.MouseListeners(:) = [];
                    thisObj.MouseLastDragPoint = nan(1,3);

                    % Toggle pickable parts of the annotation
                    if ~isempty(thisObj.AnnotationModel)
                        plotH = [thisObj.AnnotationModel.Plot];
                        plotH(~isvalid(plotH)) = [];
                        set(plotH,'PickableParts','none');
                    end

                    % Mark annotation editing stopped
                    set(thisObj.AnnotationModel,'IsBeingEdited',false);

                    % Notify listeners
                    evt = wt.event.ToolInteractionData('AnnotationStopped',thisObj);
                    thisObj.notify('AnnotationStopped',evt);

                end
            end
        end %function

    end %methods

    %% Protected Methods
    methods (Access = protected)

        function onStart(~)
            % Triggered on edit start
        end %function

        function onStop(~)
            % Triggered on edit stop
        end %function

        function onMouseRelease(~,~)
            % Triggered on mouse button up
        end %function

        function onMouseDrag(~,~)
            % Triggered on mouse dragged
        end %function

        function onMouseMotion(~,~)
            % Triggered on mouse moving
        end %function

        function updatePointer(~)
            % Triggered on mouse moving in clickable axes
        end %function

        function tf = isClickableAxes(obj,e)
            % Was the click within an object in the clickable axes?

            % What object was clicked?
            hitObject = e.HitObject;

            % Was the click within the clickable axes?
            ax = obj.ClickableAxes;

            % Was the click on an axes toolbar button?
            hitToolbar = ancestor(hitObject,'matlab.ui.controls.AxesToolbar');

            % Was the click on an object within the axes?
            tf = ~isempty(hitObject) && isempty(hitToolbar);
            if ~tf
                return
            end

            % Ignore sporadic blips outside the axes (use axes container boundaries)
            pos = e.IntersectionPoint;
            if all(isnan(pos))  % outside central image area
                % pointer is outside inner axes, possibly outside outer ones too
                pos = e.Point;
                axPos = round(getpixelposition(ax.Parent,true));
                tf = pos(1) >= axPos(1) && pos(1) <= axPos(1)+axPos(3) && ...
                    pos(2) >= axPos(2) && pos(2) <= axPos(2)+axPos(4);
                if ~tf
                    return
                end
            end

            % Ignore if a zoom mode is on
            persistent toolButtons toolAxes
            if isempty(toolButtons) || isempty(toolAxes) || ~isequal(toolAxes, ax)
                toolAxes = ax
                axTbar = ax.Toolbar;
                toolButtons = axTbar.Children;
            end

            try %#ok<TRYNC>
                toolButtons = toolButtons(isvalid(toolButtons));
            end

            if ~isempty(toolButtons)
                isModeButton = contains({toolButtons.Tag},["zoom","pan","rotate"]);
                modeIsActive = [toolButtons(isModeButton).Value];
                tf = tf && ~any(modeIsActive);
            end

        end %function

    end %methods



    %% Private Methods
    methods (Access=private)

        function onMousePress_private(obj,e)

            % Proceed if the click was within the monitored axes
            if isClickableAxes(obj,e)

                % Track the last point for drag operation
                point = e.IntersectionPoint;
                if all(isnan(point))
                    point = obj.ClickableAxes.CurrentPoint(2,:);
                end
                obj.MouseLastDragPoint = point;

                % Prepare eventdata
                evt.CurrentPoint = point;
                evt.SelectionType = e.Source.SelectionType;
                evt.HitObject = e.HitObject;

                % Call method
                obj.onMousePress(evt);

            end %if isClickableAxes(obj,e)

        end %function


        function onMouseRelease_private(obj,e)

            % Track the last point for drag operation
            obj.MouseLastDragPoint = nan(1,3);

            % Prepare eventdata
            point = e.IntersectionPoint;
            if all(isnan(point))
                point = obj.ClickableAxes.CurrentPoint(2,:);
            end
            evt.CurrentPoint = point;

            % Call method
            obj.onMouseRelease(evt);

        end %function


        function onMouseMotion_private(obj,e)

            % Track the current object beneath the mouse
            obj.CurrentHitObject = e.HitObject;

            % Proceed if the motion was within the monitored axes
            if isClickableAxes(obj,e)

                % Get actual axes point, even outside central image area
                point = e.IntersectionPoint;
                if all(isnan(point))
                    point = obj.ClickableAxes.CurrentPoint(2,:);
                end
                evt = struct('Source',e.Source, 'IntersectionPoint',point);

                % Callback for mouse moving
                obj.onMouseMotion(evt);

                % Change the figure pointer
                obj.updatePointer();

                % Is drag occurring?
                if obj.IsDragging

                    % Prepare eventdata
                    evt.CurrentPoint = evt.IntersectionPoint;
                    evt.StartPoint = obj.MouseLastDragPoint;
                    evt.SelectionType = evt.Source.SelectionType;

                    % Track the last point for drag operation
                    obj.MouseLastDragPoint = evt.IntersectionPoint;

                    % Call method
                    obj.onMouseDrag(evt);

                end %if ~any(ismissing(obj.MouseLastDragPoint))

            else

                % If not over the axes, use standard pointer
                wt.utility.fastSet(obj.CurrentFigure,"Pointer","arrow")

            end %if isClickableAxes(obj,e)

        end %function

    end %methods



    %% Get/Set Methods
    methods
        function value = get.Type(obj)
            value = string(class(obj));
        end

        function value = get.IsStarted(obj)
            value = ~isempty(obj.MouseListeners);
        end

        function value = get.IsDragging(obj)
            value = ~any(ismissing(obj.MouseLastDragPoint)) ;
        end
    end

end % classdef