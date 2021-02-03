classdef TopComponent < matlab.ui.componentcontainer.ComponentContainer
   
    properties
       SubComponent SubComponent
    end
    
    
    methods (Access = protected)
        
        function setup(obj)
            
            obj.SubComponent.PropA = 3;
            
        end %function
        
        
        function update(obj)
            
        end %function
        
    end %methods
    
end %classdef

