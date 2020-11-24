classdef (Hidden, Abstract) BaseAnnotationModel < uiw.model.BaseModel ...
        & matlab.mixin.Heterogeneous
    % AnnotationModel - Base class for annotation models
    %
    %
    % Notes:
    %
    %
    
    % Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 297 $
    %   $Date: 2018-09-05 15:55:42 -0400 (Wed, 05 Sep 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Public Properties
    properties (AbortSet, SetObservable)
        Name (1,:) char %Name of this annotation
        Color (1,3) double {mustBeNonnegative, mustBeLessThanOrEqual(Color,1)} = [0 .6 1] %Color of the annotation
        Alpha (1,1) double {mustBeFinite, mustBeNonnegative, mustBeLessThanOrEqual(Alpha,1)} = 1 % Alpha setting
        IsVisible (1,1) logical = true; % Whether to show this annotation or not
        IsSelected (1,1) logical = false; % Whether to highlight this annotation as selected
        IsBeingEdited (1,1) logical = false; % Whether to highlight this annotation as being edited
    end
    
    properties (AbortSet)
        Tag (1,:) char %Tag identifier of this annotation
        UserData %UserData of this annotation
    end
    
    properties (Dependent, SetAccess=immutable)
        Type %Type of annotation
    end
    
    
    %% Internal properties used for plotting
    
    properties (Hidden, Transient)
        Plot matlab.graphics.Graphics = gobjects(0); %Storage of plotting graphics objects
    end
    
    properties (Transient, SetAccess = ?uiw.mixin.AnnotationViewer)
        ShowObject (1,1) logical = true; %For viewer - whether viewer should show or not
    end
    
    properties %(Dependent, SetAccess = ?uiw.mixin.AnnotationViewer)
        HasLine (1,1) logical %Indicates if plotting graphics objects already exist
        Parent matlab.graphics.Graphics  %Parent to graphics objects
    end
    
    
    %% Constructor / destructor
    methods
        
        function obj = BaseAnnotationModel( varargin )
            % Construct the object
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            % Create listeners to observable props
            obj.createPropListeners();
            
        end %constructor
        
    end %methods
    
    
    %% Public Methods
    methods
        
        function addPoint(obj,point)
            % Adds a point to the annotation
            
            obj.Points = vertcat(obj.Points, point);
            notify(obj,'ModelChanged');
            
        end %function
        
    end %methods
    
    
    
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
            set(obj.Plot,'Parent',value); %#ok<MCSUP>
        end %function
        
        function value = get.HasLine(obj)
            value = ~isempty(obj.Plot) && all(isvalid(obj.Plot));
        end %function
        
        function value = get.Type(obj)
            value = class(obj);
        end
        
    end %methods
    
    
    
end %classdef

