classdef (Hidden) SlicePlaneViewer < uiw.abstract.WidgetContainer & uiw.mixin.HasCallback
    % SlicePlaneViewer -
    %
    %
    %
    % Syntax:
    %       obj = SlicePlaneViewer
    %       obj = SlicePlaneViewer('Property','Value',...)
    %
    % Notes:
    %
    %
    
    % Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 297 $  $Date: 2018-09-05 15:55:42 -0400 (Wed, 05 Sep 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (AbortSet)
        VolumeModel (1,1) uiw.model.VolumeModel % Data model for the volume's data
        Slice (1,3) uint16 = [1 1 1] % Slice to display in x,y,z
    end %properties
    
    properties (Dependent)
        DataAspectRatio %Aspect ratio of the imagery
    end %properties
    
    properties (Dependent, SetAccess=immutable)
        NumSlices
    end %properties
    
    properties (Transient, Access=private)
        VolumeModelChangedListener event.listener % Listener to VolumeModel changes
    end %properties
    
    
    
    %% Constructor / destructor
    methods
        
        function obj = SlicePlaneViewer(varargin)
            % Construct the control
            
            % Call superclass constructor
            obj = obj@uiw.abstract.WidgetContainer();
            
            % Change defaults
            obj.BackgroundColor = [.1 .1 .1];
            obj.ForegroundColor = [.7 .7 .7];
            
            % Create the graphics items
            obj.create();
            
            % Populate public properties from P-V input pairs
            % Need to set slice after setting VolumeModel and View
            [splitArgs,remainArgs] = uiw.mixin.AssignPVPairs.splitArgs('Slice', varargin{:});
            obj.assignPVPairs(remainArgs{:});
            obj.assignPVPairs(splitArgs{:}); %Slice
            
            % Set initial listener
            obj.attachModelListener();
            
            % Assign the construction flag
            obj.IsConstructed = true;
            
            % Redraw the widget
            obj.onResized();
            obj.onStyleChanged();
            obj.onEnableChanged();
            obj.redraw();
            
        end %constructor
        
    end %methods
    
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function create(obj)
            
            obj.hLayout.AxesContainer = uicontainer(...
                'Parent',obj.hBasePanel,...
                'Units','normalized',...
                'Position',[0 0 1 1]);
            
            obj.h.Axes = axes(...
                'Parent',obj.hLayout.AxesContainer,...
                'DataAspectRatio',[1 1 1],...
                'Visible','off',...
                'PickableParts','all',...
                'Units','normalized',...
                'Position',[0 0 1 1],...
                'View',[-37.5 30]);
            colormap(obj.h.Axes,gray(64))
            
            % Specify axes interactions
            if ~verLessThan('matlab','9.5')
                %disableDefaultInteractivity(obj.h.Axes);
                obj.h.Axes.Interactions = rotateInteraction;
                axtoolbar(obj.h.Axes,{'export','restoreview'});
            end
            
            for idx=1:3
                obj.h.SliceSurface(idx) = matlab.graphics.primitive.Surface(...
                    'Parent',obj.h.Axes,...
                    'XData',[],...
                    'YData',[],...
                    'ZData',[],...
                    'CData',[],...
                    'FaceColor','texturemap',...
                    'FaceAlpha',1,...
                    'EdgeColor','none');
            end
            
        end %function
        
        
        function redraw(obj)
            % Handle state changes that may need UI redraw
            
            % Ensure the construction is complete
            if obj.IsConstructed

                % Now, redraw the imagery per slice selections
                obj.redrawImagery();
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function redrawImagery(obj)
            % Handle state changes that may need UI redraw
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                vol = obj.VolumeModel;
                selSlice = double(obj.Slice);
                
                % YZ Slice Position
                [x,y,z] = vol.getSliceXYZ([nan selSlice(2) nan]);
                set(obj.h.SliceSurface(1),'XData',x,'YData',y,'ZData',z);
                
                % XZ Slice Position
                [x,y,z] = vol.getSliceXYZ([selSlice(1) nan nan]);
                set(obj.h.SliceSurface(2),'XData',x,'YData',y,'ZData',z);
                
                % XY Slice Position
                [x,y,z] = vol.getSliceXYZ([nan nan selSlice(3)]);
                set(obj.h.SliceSurface(3),'XData',x,'YData',y,'ZData',z);

                % CData
                if any(vol.DataSize < 1) || any(selSlice > vol.DataSize)
                    set(obj.h.SliceSurface,'CData',[]);
                else
                    obj.h.SliceSurface(1).CData = squeeze( vol.ImageData(:,selSlice(2),:) );
                    obj.h.SliceSurface(2).CData = squeeze( vol.ImageData(selSlice(1),:,:) )';
                    obj.h.SliceSurface(3).CData = squeeze( vol.ImageData(:,:,selSlice(3)) );
                end
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onModelSet(obj)
            
            % Redraw all
            obj.redraw();
            
        end %function
        
        
        function onModelChanged(obj,~)
            
            % Subclass may override this and choose to redraw based on the
            % event, if necessary for more complex scenarios.
            
            % Redraw all
            obj.redraw();
            
        end %function
        
        
        function onSliceChanged(obj,evt)
            
            % Get the new slice from the slider
            obj.Slice = evt.NewValue;
            
            % Redraw all
            obj.redraw();
            
            % Call callback
            evt.Interaction = 'Slice Changed';
            obj.callCallback(evt);
            
        end %function
        
    end %methods
    
    
    
    %% Private Methods
    methods (Access=private)
        
        function attachModelListener(obj)
            
            % Listen to changes in VolumeModel
            obj.VolumeModelChangedListener = event.listener(obj.VolumeModel,...
                'ModelChanged',@(h,e)onModelChanged(obj,e) );
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        function set.VolumeModel(obj,value)
            obj.VolumeModel = value;
            obj.attachModelListener();
            obj.onModelSet();
        end %function
        
        function value = get.DataAspectRatio(obj)
            value = obj.h.Axes.DataAspectRatio;
        end %function
        function set.DataAspectRatio(obj,value)
            obj.h.Axes.DataAspectRatio = value;
        end %function
        
        function value = get.Slice(obj)
            value = min(obj.Slice, obj.NumSlices);
        end %function
        function set.Slice(obj,value)
            value = min(value, obj.NumSlices); %#ok<MCSUP>
            value = max(value, 1);
            obj.Slice = value;
            obj.redrawImagery();
        end %function
        
        function value = get.NumSlices(obj)
            value = uint16(obj.VolumeModel.DataSize);
        end %function
        
    end %methods
    
end % classdef