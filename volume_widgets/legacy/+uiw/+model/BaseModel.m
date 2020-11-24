classdef (Hidden, Abstract) BaseModel < matlab.mixin.Copyable ...
        & matlab.mixin.CustomDisplay & uiw.mixin.AssignPVPairs ...
        & uiw.mixin.DisplayNonScalarObjectAsTable
    % BaseModel - Listens to SetObservable prop
    % ---------------------------------------------------------------------
    % Abstract: This class provides an event ModelChanged that triggers 
    % on any changes to SetObservable properties.
    %

    %   Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 58 $  $Date: 2019-05-06 09:29:55 -0400 (Mon, 06 May 2019) $
    % ---------------------------------------------------------------------
    
    %% Events
    events
        ModelChanged %Triggered when SetObservable properties are changed
    end
    
    
    %% Properties
    properties (Transient, Access = protected)
        PropListeners
    end
    
    properties (AbortSet, SetObservable, SetAccess = protected)
        IsBeingDeleted (1,1) logical = false
    end
    
    
    %% Constructor
    methods
       
        function obj = BaseModel(varargin)
            
            % Populate public properties from P-V input pairs
            obj.assignPVPairs(varargin{:});
            
            obj.createPropListeners();
            
        end %function
        
        
        function delete(obj)
            
            obj.IsBeingDeleted = true;
            
        end %destructor
        
    end %methods
    
    
    
    %% Static methods
    methods (Static)
        
        function obj = loadobj(obj)
            % Customize loading from file
           
            if isstruct(obj)
                error('Unable to load object.');
            end
            
            % Need to recreate listeners
            obj.createPropListeners();
            
        end %function
        
    end %methods
    
    
    
    %% Protected methods
    methods (Access = protected)        
        
        function createPropListeners(obj)
            
            for idx = 1:numel(obj)
                mc = metaclass(obj(idx));
                isObservable = [mc.PropertyList.SetObservable];
                props = mc.PropertyList(isObservable);
                obj(idx).PropListeners = event.proplistener(obj(idx),props,...
                    'PostSet',@(h,e)onPropChanged(obj(idx),e) );
            end %for
            
        end %function
        
        
        function onPropChanged(obj,e)
            
            evt = uiw.event.PropertyChangeEvent(...
                e.Source.Name, obj.(e.Source.Name), obj);
            obj.notify('ModelChanged',evt)
            
        end %function
        
        
      function obj = copyElement(obj)
          
         % Shallow copy object
         obj = copyElement@matlab.mixin.Copyable(obj);
         
         % Generate unique listeners
         obj.createPropListeners();
         
        end %function
        
    end %methods
    
end % classdef
