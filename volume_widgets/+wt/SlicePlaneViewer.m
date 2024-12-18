classdef SlicePlaneViewer < wt.abstract.BaseVolumeViewer
    % Volume visualization widget showing three 2D slice planes
    
    % Copyright 2018-2021 The MathWorks, Inc.
    
    
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
    
    
    
    %% Constructor
    methods 
        function obj = SlicePlaneViewer(varargin)
            
            % Call superclass constructor
            obj@wt.abstract.BaseVolumeViewer(varargin{:});
            
        end %function
    end %methods
 
    
    
    %% Setup
    methods (Access = protected)
        function setup(obj)
            
            % Call superclass setup first
            obj.setup@wt.abstract.BaseVolumeViewer(); 
            
            % Set default size
            obj.Position = [10 10 400 400];
            
            % Specify axes interactions
            enableDefaultInteractivity(obj.Axes)
            obj.Axes.Interactions = rotateInteraction;
            
            % Disable toolbar
            obj.Axes.Toolbar.Visible = 'off';
            
            % Add 3 images
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