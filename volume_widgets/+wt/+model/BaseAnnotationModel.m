classdef (Abstract) BaseAnnotationModel < wt.model.BaseModel ...
        & matlab.mixin.Heterogeneous ...
        & wt.mixin.DisplayNonScalarObjectAsTable
    % Base class for annotation models
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    %% Abstract Properties
    properties (Abstract, SetAccess = protected)
        
        % What is the default editing tool for the annotation?
        EditingTool (1,1) string
        
    end %properties
    
    
    
    %% Abstract Methods
    methods (Abstract, Access = protected)
        
        % Create the graphics object for one instance
        createOne(obj,parent)
        
        % Redraw the graphics object for one instance
        redrawOne(obj)
        
    end %methods
    
    
    
    %% Public Properties
    properties (AbortSet, SetObservable)
        
        % Name of this annotation
        Name (1,1) string
        
        % Display color of the annotation
        Color (1,3) double {mustBeNonnegative, mustBeLessThanOrEqual(Color,1)} = [0 .6 1]
        
        % Display alpha of the annotation
        Alpha (1,1) double {mustBeFinite, mustBeNonnegative, mustBeLessThanOrEqual(Alpha,1)} = 0.5
        
        % Should the annotation be shown?
        IsVisible (1,1) logical = true;
        
        % Should the annotation be highlighted for selection?
        IsSelected (1,1) logical = false;
        
        % Is this annotation being edited?
        IsBeingEdited (1,1) logical = false;
        
    end %properties
    
    
    properties (AbortSet)
        
        % Tag identifier of this annotation
        Tag (1,:) char
        
        % UserData of this annotation
        UserData
        
    end %properties
    
    
    
    %% Internal properties used for plotting
    
    properties (Transient, Hidden, SetAccess = protected)
        
        % Storage of plotting graphics objects
        Plot (1,:) matlab.graphics.Graphics = gobjects(1,0);
        
    end %properties
        
    
    properties (AbortSet, SetObservable, Transient, SetAccess = ?wt.mixin.AnnotationViewer)
        
        % Visibility of the annotation, as toggled by the annotation viewer
        ShowObject (1,1) logical = true;
        
        % Current In-slice range, as indicated by the annotation viewer
        SliceRangeFilter (3,2) double = inf(3,2) .* [-1 1]
        
    end %properties
    
    
    properties (Dependent, SetAccess = protected)
        
        % Indicates if plotting graphics objects already exist
        HasLine (1,1) logical
        
        % Parent to graphics objects
        Parent matlab.graphics.Graphics
        
        % Type of annotation
        Type
        
    end %properties
    
    
    properties (Constant, Access = protected)
        
        % The color to use to show a selected annotation
        SELECTEDCOLOR = [1 1 0];
        
        % The color to use to show an annotation is being edited
        EDITINGCOLOR = [.2 1 .2];
        
    end %properties
    
    
    %% Constructor / destructor
    methods
        
        function obj = BaseAnnotationModel(varargin)
            
            % Call superclass constructors
            obj@wt.model.BaseModel(varargin{:});
            
        end %constructor
        
        
        function delete(obj)
            
            % Delete any graphics
            obj.unplot();
            
        end %destructor
        
    end %methods
    
    
    
    %% Sealed public methods (need for Heterogeneous arrays)
    methods (Sealed)
        
        function plot(obj,parent)
            % Plot each annotation
            
            % Loop on annotations
            for thisObj = obj(:)'
                
                % Clear any invalid plots
                if ~isempty(thisObj.Plot) && any(~isvalid(thisObj.Plot))
                    delete(thisObj.Plot);
                    thisObj.Plot(:) = [];
                end
                
                % Check existing plot and visibility
                hasPlot = ~isempty(thisObj.Plot) && all(isvalid(thisObj.Plot));
                
                % Create the plot if not already there
                if ~hasPlot
                    thisObj.createOne(parent);
                    thisObj.redrawOne();
                end %if ~hasPlot
                
            end %for
            
        end %function
        
        
        function unplot(obj)
            % Unplot each annotation
            
            for thisObj = obj(:)'
                if isvalid(thisObj)
                    validPlots = thisObj.Plot(isvalid(thisObj.Plot));
                    delete(validPlots)
                end
            end
        
        end %function
        
        
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
        
    end %methods
    
    
    
    %% Sealed protected methods (need for Heterogeneous arrays)
    methods (Sealed, Access = protected)
        
        function onPropChanged(obj,e)
            
            if ~isempty(obj.Plot) && all(isvalid(obj.Plot))
                
                % Debug
                % annName = obj.Name;
                % propName = e.Source.Name;
                % fprintf("Redraw '%s' due to property '%s'\n",annName,propName);
                
                % Update any plots
                obj.redrawOne()
                
            end %if
            
            % Call superclass method
            obj.onPropChanged@wt.model.BaseModel(e);
            
        end %function
        
    end %methods
    
    
    %% Get/Set Methods
    methods
        
        function value = get.Parent(obj)
            if obj.HasLine
                value = obj.Plot(1).Parent;
            else
                value = gobjects(0);
            end
        end %function
        
        function set.Parent(obj,value)
            set(obj.Plot,'Parent',value);
        end %function
        
        function value = get.HasLine(obj)
            value = ~isempty(obj.Plot) && all(isvalid(obj.Plot));
        end %function
        
        function value = get.Type(obj)
            value = class(obj);
        end
        
    end %methods
       
    
end %classdef

