classdef SlicePlaneViewer < wt.BaseVolumeViewer
    % Volume visualization widget showing three 2D slice planes
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    
    %% Properties
    properties (AbortSet)
        
        % Current Slice to display in each dimension [x,y,z]
        Slice (1,3) double {mustBeInteger,mustBeFinite,mustBePositive} = [1 1 1]
        
    end %properties
    
    
    
    %% Internal Properties
    properties (Transient, Hidden, SetAccess = protected)
        
        % The image surface
        Image matlab.graphics.primitive.Surface
        
    end %properties
    
 
    
    %% Setup
    methods (Access = protected)
        function setup(obj)
            
            % Call superclass setup first
            obj.setup@wt.BaseVolumeViewer(); 
            
            % Specify axes interactions
            enableDefaultInteractivity(obj.Axes)
            obj.Axes.Interactions = rotateInteraction;
            
            % Create the custom axes toolbar
            % This must be done after setup due to g2318236
            %RAJ - just disabling toolbar for performance
            %axtoolbar(obj.Axes,{'export','restoreview'});
            
            for idx=1:3
                obj.Image(idx) = obj.createImagePlot();
            end
            
        end %function
    end %methods
    
    
    
    %% Update
    methods (Access = protected)
        function update(obj)
            
            % Get the slice information
            currentSlice = obj.Slice;
            
            if all(obj.VolumeModel.DataSize > 0)
                
                % YZ Slice Position
                [x,y,z] = obj.VolumeModel.getSliceXYZ([nan currentSlice(2) nan]);
                set(obj.Image(1),'XData',x,'YData',y,'ZData',z);
                
                % XZ Slice Position
                [x,y,z] = obj.VolumeModel.getSliceXYZ([currentSlice(1) nan nan]);
                set(obj.Image(2),'XData',x,'YData',y,'ZData',z);
                
                % XY Slice Position
                [x,y,z] = obj.VolumeModel.getSliceXYZ([nan nan currentSlice(3)]);
                set(obj.Image(3),'XData',x,'YData',y,'ZData',z);
                
                % CData
                obj.Image(1).CData = squeeze( obj.VolumeModel.ImageData(:,currentSlice(2),:) );
                obj.Image(2).CData = squeeze( obj.VolumeModel.ImageData(currentSlice(1),:,:) )';
                obj.Image(3).CData = squeeze( obj.VolumeModel.ImageData(:,:,currentSlice(3)) );
                
            else
                set(obj.Image,'CData',[]);
            end
            
        end %function
    end %methods
    
    
    %% Get/Set Methods
    methods
        
        function value = get.Slice(obj)
            if isempty(obj.VolumeModel.DataSize)
                value = obj.Slice;
            else
                value = min(obj.Slice, obj.VolumeModel.DataSize');
                value(value<1) = 1;
            end
        end %function
        
    end %methods
    
end % classdef