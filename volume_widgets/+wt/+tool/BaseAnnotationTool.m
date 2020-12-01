classdef BaseAnnotationTool < handle & matlab.mixin.Heterogeneous
    % & wt.abstract.HandleClassBase
    % Base class for annotation tools
    
    % Copyright 2020 The MathWorks, Inc.
    
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
            
            % Find the figure
            hFigure = ancestor(obj.ClickableAxes,'figure');
            if isempty(hFigure) || ~isvalid(hFigure)
                error('Tool requires axes plaxed in figure before start.');
            end
            
            % Start listeners to window mouse events
            obj.MouseListeners = [
                event.listener(hFigure,'WindowMousePress',@(h,e)onMousePress_private(obj,e))
                event.listener(hFigure,'WindowMouseRelease',@(h,e)onMouseRelease_private(obj,e))
                event.listener(hFigure,'WindowMouseMotion',@(h,e)onMouseMotion_private(obj,e))
                ];
            %event.listener(hFigure,'WindowScrollWheel',@(h,e)onMouseScroll_private(obj,e))
            
            % Notify listeners
            evt = wt.event.ToolInteractionData('AnnotationStarted',obj);
            obj.notify('AnnotationStarted',evt);
            
        end %function
        
        
        function stop(obj)
            for thisObj = obj(:)'
                if thisObj.IsStarted
                    
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
        
        function onMouseRelease(~,~)
            % Triggered on mouse button up
            
        end %function
        
        
        function onMouseDrag(~,~)
            % Triggered on mouse dragged
            
        end %function
        
    end %methods
    
    
    
    %% Private Methods
    methods (Access=private)
        
        function tf = isClickableAxes(obj,e)
            % Was the click within an object in the clickable axes?
            hitObject = e.HitObject;
            tf = ~isempty(hitObject) && any( obj.ClickableAxes ==...
                ancestor(hitObject,'matlab.graphics.axis.AbstractAxes') );
        end
        
        
        function onMousePress_private(obj,e)
            
            % Proceed if the click was within the monitored axes
            if isClickableAxes(obj,e)
                
                % Track the last point for drag operation
                obj.MouseLastDragPoint = e.IntersectionPoint;
                
                % Prepare eventdata
                evt.CurrentPoint = e.IntersectionPoint;
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
            evt.CurrentPoint = e.IntersectionPoint;
            
            % Call method
            obj.onMouseRelease(evt);
            
        end %function
        
        
        function onMouseMotion_private(obj,e)
            
            % Track the current object beneath the mouse
            obj.CurrentHitObject = e.HitObject;
            
            % Proceed if the click was within the monitored axes
            if isClickableAxes(obj,e) && ~any(ismissing(obj.MouseLastDragPoint))
                
                % Prepare eventdata
                evt.CurrentPoint = e.IntersectionPoint;
                evt.StartPoint = obj.MouseLastDragPoint;
                evt.SelectionType = e.Source.SelectionType;
                
                % Track the last point for drag operation
                obj.MouseLastDragPoint = e.IntersectionPoint;
                
                % Call method
                obj.onMouseDrag(evt);
                
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
    end
    
end % classdef