classdef AnnotatedIsosurfaceViewer < wt.IsosurfaceViewer & wt.mixin.AnnotationViewer
    % Isosurface annotation widget with a single 3D view
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    
    %% Internal Properties
    properties (Hidden, SetAccess = protected)
        
        % Lighting
        HoverLabel matlab.ui.control.Label
        
    end %properties
    
    
    %% Setup
    methods (Access = protected)
        function setup(obj)
            
            % Call superclass setup first
            obj.setup@wt.IsosurfaceViewer();
            
            % Add hover label
            obj.HoverLabel = uilabel(obj);
            obj.HoverLabel.Position = [20 5 400 40];
            obj.HoverLabel.FontColor = [.7 .7 .4];
            obj.HoverLabel.FontSize = 16;
            obj.HoverLabel.Text = '';
            
            % Assign the parent for annotations
            obj.AnnotationParent = obj.Axes;
            
        end %function
    end %methods
    
    
    %% Update
    methods (Access = protected)
        function update(obj,varargin)
            
            % Call superclass update first
            obj.update@wt.IsosurfaceViewer(varargin{:});
            
            % Clean-up
            obj.removeInvalidAnnotations();
            
        end %function
    end %methods
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function onMouseHoverChanged(obj,~)
            % Occurs when an active tool hovers over an object
            
            % Trap errors and ignore them
            try
                
                % Determine what object the mouse is hovering over
                hitObj = obj.CurrentTool.CurrentHitObject;
                if isempty(hitObj)
                    hitName = "";
                elseif isempty(hitObj.UserData)
                    className = class(hitObj);
                    nameParts = extract(className,alphanumericsPattern);
                    hitName = nameParts{end};
                elseif isprop(hitObj.UserData,'Name')
                    name = char(hitObj.UserData.Name);
                    if isempty(name)
                        hitName = class(hitObj.UserData);
                    else
                        hitName = name;
                    end
                else
                    hitName = class(hitObj.UserData);
                end
                
            catch
                hitName = "";
            end %try
            
            % Update the display
            obj.HoverLabel.Text = hitName;
            
        end %function
        
    end %methods
    
    
    
end % classdef