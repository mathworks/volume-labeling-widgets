classdef Select < wt.tool.BaseAnnotationTool
    % Tool for selecting annotations
    
    % Copyright 2020 The MathWorks, Inc.
    
    
    %% Properties
    properties (SetAccess = protected)
        
        % The annotations that may be selected
        AnnotationModel 
        
    end %properties
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function onMousePress(obj,evt)
            % Triggered on mouse button down
            
            % Only act on regular clicks
            if any(evt.SelectionType == ["normal","alt"])
                
                % See if the hit graphics object is linked to an annotation
                hitObject = evt.HitObject;
                ud = hitObject.UserData;
                if isscalar(ud) && isa(ud,'wt.model.BaseAnnotationModel') && isvalid(ud)
                    aObjHit = ud;
                else
                    aObjHit = wt.model.BaseAnnotationModel.empty(0);
                end
                
                % Get valid annotation models
                aObj = obj.AnnotationModel(isvalid(obj.AnnotationModel));
                
                % Was an annotation hit?
                if isempty(aObjHit)
                    % No - deselect all annotations
                    
                    % Deselect all annotations
                    if ~isempty(aObj)
                        set(aObj,'IsSelected',false);
                        
                        % Notify listeners
                        evt = wt.event.ToolInteractionData('AnnotationSelected',...
                            obj, aObj([]), evt.CurrentPoint([2 1 3]) );
                        obj.notify('AnnotationSelected',evt);
                        
                    end %if ~isempty(aObj)
                    
                else
                    % Yes - select the new annotations
                    
                    % Get other annotations to be deselected
                    aObjDesel = aObj(aObj ~= aObjHit);
                    
                    % Toggle selections
                    set(aObjDesel,'IsSelected',false);
                    set(aObjHit,'IsSelected',true);
                    
                end %if isempty(aObjHit)
                
                % Update the annotation models' state
                %set(aObjHit,'IsBeingEdited',false);
                
                % Notify listeners
                evt = wt.event.ToolInteractionData('AnnotationSelected',...
                    obj, aObjHit, evt.CurrentPoint([2 1 3]) );
                obj.notify('AnnotationSelected',evt);
                
            end %if any(evt.SelectionType == ["normal","alt"])
            
        end %function
        
    end %methods
    
end % classdef