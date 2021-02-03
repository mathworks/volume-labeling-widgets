classdef SetupTestComponent_Fixed < matlab.ui.componentcontainer.ComponentContainer
    
    %% Properties
    properties
        Number (1,1) double
    end
    
    properties (Access = protected)
        EditField matlab.ui.control.NumericEditField
        MySetupComplete (1,1) logical = false
    end
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function setup(obj)
            disp('setup start');
            
            obj.CreateFcn = @(src,evt)markMySetupComplete(obj);
            
            % Load default dataset
            % Triggers set.Number which could call update during setup!
            obj.loadDefaultValue(); 
            
            % Create the controls
            g = uigridlayout(obj,[1 1]);
            obj.EditField = uieditfield(g,'numeric');
            
            disp('setup finish');
        end
        
        
        function update(obj)
            disp('update');
            
            % Update the control
            obj.EditField.Value = obj.Number;
            
        end
        
        
        function loadDefaultValue(obj)
            % Loads in a default dataset
            disp('loadDefaultValue');
            
            persistent defaultValue
            if isempty(defaultValue)
                % Load value from file here
                defaultValue = 5;
            end
            
            obj.Number = defaultValue;
        end
        
        
        function markMySetupComplete(obj)
            disp('markMySetupComplete');
            obj.MySetupComplete = true;
        end
        
    end %methods
    
    
    %% Accessors
    methods
        
        function set.Number(obj, value)
            disp('set.Number');
            obj.Number = value;
            if obj.MySetupComplete %#ok<MCSUP>
                obj.update();
            end
        end
        
    end %methods
    
end %classdef

