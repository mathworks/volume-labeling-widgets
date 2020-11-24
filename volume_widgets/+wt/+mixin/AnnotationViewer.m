classdef (Abstract) AnnotationViewer < handle
    % Mixin class for an interactive viewer and editor that displays annotation of graphics
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    
    %% Events
    events
        
        % When annotation editing begins
        AnnotationStarted
        
        % When annotation editing ends
        AnnotationStopped
        
        % When the selected annotation changes
        AnnotationSelected
        
        % When the array of AnnotationModel has changed
        AnnotationModelChanged
        
        % When an annotation model has an internal change
        AnnotationChanged
        
    end %events
    
    
    %% Properties
    properties (AbortSet)
        
        % Data model for the annotations
        AnnotationModel (1,:) wt.model.BaseAnnotationModel 
        
    end %properties
    
    
    properties (AbortSet, SetAccess = private)
        
        % List of all instantiated annotation tools
        Tool (1,:) wt.tool.BaseAnnotationTool
        
        % Currently selected annotation tool
        CurrentTool wt.tool.BaseAnnotationTool
        
    end %properties
    
    
    properties (Dependent, SetAccess = private)
        
        % Currently selected annotation
        SelectedAnnotationModel (1,:) wt.model.BaseAnnotationModel
        
        % Currently being added annotation
        PendingAnnotationModel (1,:) wt.model.BaseAnnotationModel 
        
        %Indicates if an annotation is currently being added interactively
        IsAddingInteractiveAnnotation (1,1) logical 
        
    end %properties
    
    
    
    %% Internal Properties
    properties (Transient, AbortSet, Access=protected)
        
        % Parent axes for annotations - subclass should set
        AnnotationParent matlab.graphics.Graphics {mustBeScalarOrEmpty} 
        
        % Listener to AnnotationModel changes
        AnnotationModelChangedListener event.listener 
        
        % Listener to Annotation selection changes
        AnnotationSelectedListener event.listener 
        
        % Listener to tools starting
        ToolStartedListener event.listener 
        
        % Listener to tools stopping
        ToolStoppedListener event.listener 
        
        % When the mouse passes over a different object
        MouseHoverListener event.listener 
        
    end %properties
    
    
    
    %% Abstract Methods
    methods (Access = protected)
        
        update(obj)
        
    end %methods
    
    
    
    %% Public Methods
    methods
        
        function selectAnnotation(obj, aObj)
            % Select annotation by index or object
            
            % Validate arguments
            arguments
                obj (1,1) wt.mixin.AnnotationViewer
                aObj wt.model.BaseAnnotationModel = wt.model.BaseAnnotationModel.empty(0);
            end %arguments
            
            % Clean-up
            obj.removeInvalidAnnotations();
            
            % Is an annotation already happening? If so, finish it.
            if obj.IsAddingInteractiveAnnotation
                obj.finishAnnotation();
            end
            
            % Change the selections on the models
            isMatch = aObj == obj.AnnotationModel;
            set(obj.AnnotationModel(~isMatch),'IsSelected',false);
            set(obj.AnnotationModel( isMatch),'IsSelected',true);
            
        end %function
        
        
        function addAnnotation(obj,aObj)
            
            % Validate arguments
            arguments
                obj (1,1) wt.mixin.AnnotationViewer
                aObj (1,:) wt.model.BaseAnnotationModel {mustBeNonempty}
            end %arguments
            
            % Append the list, removing duplicates
            obj.AnnotationModel = horzcat( obj.AnnotationModel, aObj(:) );
            
        end %function
        
        
        function aObj = addInteractiveAnnotation(obj,aObj)
            
            % Validate arguments
            arguments
                obj (1,1) wt.mixin.AnnotationViewer
                aObj (1,1) wt.model.BaseAnnotationModel = wt.model.PointsAnnotation();
            end %arguments
            
            % Ensure it has a name
            if isempty(aObj.Name)
                id = numel(obj.AnnotationModel) + 1;
                aObj.Name = sprintf('Annotation %d',id);
            end
            
            % Is an annotation already happening? If so, finish it.
            if obj.IsAddingInteractiveAnnotation
                obj.finishAnnotation();
            end
            
            % Add this annotation to the list, so it can be displayed
            obj.addAnnotation(aObj);
            
            % Select it in the AnnotatedVolumeViewer also
            obj.selectAnnotation(aObj);
            
            % Launch the tool
            obj.launchEditingTool(aObj,false)
            
        end %function
    
    
        function launchSelectTool(obj)
            % Launch the select tool
            
            obj.launchEditingTool(obj.AnnotationModel,false,'wt.tool.Select')
            
        end %function
        
        
        function launchEditingTool(obj,aObj,erase,toolName)
            % Launch the editing tool for the given annotation
            
            % Validate arguments
            arguments
                obj (1,1) wt.mixin.AnnotationViewer
                aObj (1,:) wt.model.BaseAnnotationModel
                erase (1,1) logical = false;
                toolName char = aObj.EditingTool
            end %arguments
            
            % Clear any invalid tools
            obj.Tool(~isvalid(obj.Tool)) = [];
            
            % Is the tool already launched?
            openTools = string([obj.Tool.Type]);
            isMatch = openTools == toolName;
            
            % Turn off any other editing tools that are running
            obj.Tool(~isMatch).stop();
            
            % Is the tool already loaded??
            if any(isMatch)
                
                % Yes - use the existing tool
                thisTool = obj.Tool(isMatch);
                
            else
                % No
                
                % Launch the tool
                toolConstructor = str2func(toolName);
                thisTool = toolConstructor();
                obj.Tool = horzcat(obj.Tool, thisTool);
                
                % Update listeners
                obj.ToolStartedListener = event.listener(obj.Tool,...
                    'AnnotationStarted',@(h,e)onToolStarted(obj,e) );
                obj.ToolStoppedListener = event.listener(obj.Tool,...
                    'AnnotationStopped',@(h,e)onToolStopped(obj,e) );
                obj.AnnotationSelectedListener = event.listener(obj.Tool,...
                    'AnnotationSelected',@(h,e)onAnnotationSelected(obj,e) );
                
                prop = findprop(thisTool,'CurrentHitObject');
                obj.MouseHoverListener = event.proplistener(obj.Tool,...
                    prop,'PostSet',@(h,e)onMouseHoverChanged(obj,e) );
            end %if
            
            % Select the annotation
            if ~isa(thisTool,'wt.tool.Select') 
                obj.selectAnnotation(aObj);
            end
            
            % Start the tool
            thisTool.Erase = erase;
            thisTool.start(aObj, obj.AnnotationParent);
            
        end %function
        
        
        function finishAnnotation(obj)
            % Complete the annotation
            
            % Turn off any editing tools that are running
            obj.Tool.stop();
            
            % Toggle off the editing display
            if obj.IsAddingInteractiveAnnotation
                set(obj.PendingAnnotationModel,'IsBeingEdited',false);
            end
            
        end %function
        
        
        function cancelAnnotation(obj,~)
            
            % Turn off any editing tools that are running
            obj.Tool.stop();
            
            % Remove the annotation model
            pendingAnnotation = obj.PendingAnnotationModel;
            if ~isempty(pendingAnnotation)
                obj.removeAnnotation(pendingAnnotation);
            end
            
        end %function
        
        
        function removeAnnotation(obj,aObj)
            % Remove annotation by object
            
            % Validate arguments
            arguments
                obj (1,1) wt.mixin.AnnotationViewer
                aObj (1,:) wt.model.BaseAnnotationModel
            end %arguments
            
            % Stop any editing of the annotations being removed
            if any(aObj == obj.PendingAnnotationModel)
                obj.Tool.stop();
            end
            
            % Update the list of annotations
            isBeingRemoved = ismember(obj.AnnotationModel, aObj);
            obj.AnnotationModel(isBeingRemoved) = [];
            
        end %function
        
    end %methods
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function tf = isAnnotationPlot(~,plotObj)
            % Checks if the specified graphics object is an annotation plot
            
            tf = isscalar(plotObj) && ishghandle(plotObj) && ...
                isprop(plotObj,'UserData') && isscalar(plotObj.UserData) && ...
                isa(plotObj.UserData,'wt.model.BaseAnnotationModel');
            
        end %function
        
        
        function varargout = removeInvalidAnnotations(obj,aObj)
            
            if nargin > 1
                varargout{1} = aObj(isvalid(aObj));
            end
            
            if ~all(isvalid(obj.AnnotationModel))
                obj.AnnotationModel(~isvalid(obj.AnnotationModel)) = [];
            end
            
        end %function
        
        
        function onToolStarted(obj,evt)
            
            % Turn off any other editing tools
            selTool = evt.Source;
            deselTool = obj.Tool(obj.Tool ~= selTool);
            deselTool.stop();
                        
            % Notify listeners
            obj.notify('AnnotationStarted',evt);
            
        end %function
        
        
        function onToolStopped(obj,evt)
            
            % Notify listeners
            obj.notify('AnnotationStopped',evt);
            
        end %function
        
        
        function onAnnotationSelected(obj,evt)
            
            % Notify listeners
            obj.notify('AnnotationSelected',evt);
            
        end %function
        
        
        function onAnnotationModelChanged(obj,evt)
            % Handle changes to an AnnotationModel - subclass may override
            
            % Notify listeners
            obj.notify('AnnotationChanged',evt);
            
        end %function
        
        
        function onMouseHoverChanged(obj,~)
            % Occurs when an active tool hovers over an object
            
%             % For debug - what was hit?     
%             hitObj = obj.CurrentTool.CurrentHitObject;
%             if isempty(hitObj)
%                 disp('empty');
%             elseif isempty(hitObj.UserData)
%                 disp(class(hitObj));
%             elseif isprop(hitObj.UserData,'Name')
%                 disp(hitObj.UserData.Name);
%             else
%                 disp(class(hitObj.UserData));
%             end
            
        end %function
        
    end %methods
    
    
    
    %% Private Methods
    methods (Access=private)
        
        function onAnnotationModelSet(obj, oldValue)
            
            % Remove any old plots
            aObjRemoved = setdiff(oldValue, obj.AnnotationModel);
            aObjRemoved.unplot();
            
            % Plot any new annotations
            obj.AnnotationModel.plot(obj.AnnotationParent)
            
            % Listen to changes in AnnotationModel
            obj.AnnotationModelChangedListener = event.listener(obj.AnnotationModel,...
                'PropertyChanged',@(h,e)onAnnotationModelChanged(obj,e) );
            
            % Notify listeners
            obj.notify('AnnotationModelChanged');
            
        end %function
        
    end %methods
    
    
    
    %% Accessors
    methods
        
        function value = get.CurrentTool(obj)
            selIdx = [obj.Tool.IsStarted];
            value = obj.Tool(selIdx);
        end
        
        function value = get.IsAddingInteractiveAnnotation(obj)
            %curTool = obj.CurrentTool;
            %value = isscalar(curTool) && ~isa(curTool,'wt.tool.Select');
            value = any([obj.AnnotationModel.IsBeingEdited]);
        end
        
        function value = get.SelectedAnnotationModel(obj)
            isSelected = [obj.AnnotationModel.IsSelected];
            if any(isSelected)
                value = obj.AnnotationModel(isSelected);
            else
                value = wt.model.BaseAnnotationModel.empty(1,0);
            end
        end
        
        function value = get.PendingAnnotationModel(obj)
            isBeingEdited = [obj.AnnotationModel.IsBeingEdited];
            if any(isBeingEdited)
                value = obj.AnnotationModel(isBeingEdited);
            else
                value = wt.model.BaseAnnotationModel.empty(1,0);
            end
        end
    
        function set.AnnotationModel(obj,value)
            value = unique(value, 'stable');
            value(~isvalid(value)) = [];
            oldValue = obj.AnnotationModel;
            obj.AnnotationModel = value;
            obj.onAnnotationModelSet(oldValue);
        end
        
    end %methods
    
end % classdef