classdef (Hidden) VolumeViewer < uiw.abstract.WidgetContainer & uiw.mixin.HasCallback
    % VolumeViewer -
    %
    %
    %
    % Syntax:
    %       obj = VolumeViewer
    %       obj = VolumeViewer('Property','Value',...)
    %
    % Notes:
    %
    %
    
    % Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 336 $  $Date: 2019-05-17 16:21:36 -0400 (Fri, 17 May 2019) $
    % ---------------------------------------------------------------------
    
    
    %% Properties
    properties (AbortSet)
        VolumeModel (1,1) uiw.model.VolumeModel % Data model for the volume's data
        View char {mustBeMember(View,{'xy','xz','yz'})} = 'xy' % View plane
        Slice (1,1) uint16 = 1 % Slice to display
        EnableViewSelection (1,1) logical = true %Enable popup to select view
        ShowAxes (1,1) logical = false %Show or hide the axes, ticks, etc.
        ShowGrid (1,1) logical = false %Show or hide the grid
    end %properties
    
    properties (Dependent)
        DataAspectRatio %Aspect ratio of the imagery
    end %properties
    
    properties (Dependent, SetAccess=immutable)
        NumSlicesCurrentView
        SliceDimension %Logical array giving dimension of slices into the 2D view [Y X Z]
    end %properties
    
    
    %% Internal Properties
    properties (Transient, Access=private)
        VolumeModelChangedListener event.listener % Listener to VolumeModel changes
    end %properties
    
    properties (Constant, Access=protected)
        VIEWS string = ["XY","XZ","YZ"] %View plane definitions
    end %properties
    
    
    
    %% Constructor / destructor
    methods
        
        function obj = VolumeViewer(varargin)
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
        
        function redraw(obj)
            % Handle state changes that may need UI redraw
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                obj.redrawSliceSelection();
                
                % View popup
                selViewIdx = find(obj.SliceDimension([3 1 2]));
                if obj.EnableViewSelection
                    obj.h.ViewIndicator.Style = 'popup';
                    obj.h.ViewIndicator.String = obj.VIEWS;
                    obj.h.ViewIndicator.Value = selViewIdx;
                else
                    obj.h.ViewIndicator.Style = 'text';
                    obj.h.ViewIndicator.String = obj.VIEWS{selViewIdx};
                end
                
                % Set viewing angle and direction
                viewVec = -double(obj.SliceDimension([2 1 3]));
                view(obj.h.Axes, viewVec);
                
                % Show axes?
                if obj.ShowAxes
                    obj.h.Axes.Visible = 'on';
                    obj.h.Axes.OuterPosition = [0 0 1 1];
                else
                    obj.h.Axes.Visible = 'off';
                    obj.h.Axes.Position = [0 0 1 1];
                end
                
                % Show Grid?
                if obj.ShowGrid
                    grid(obj.h.Axes,'on');
                else
                    grid(obj.h.Axes,'off');
                end
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function redrawSliceSelection(obj)
            % Handle state changes that may need UI redraw
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                obj.redrawImagery();
                
                % Don't let panning turn off automatic axes limits on the
                % slice axis
                if obj.SliceDimension(1)
                    % Viewing XZ Plane with Y slices
                    obj.h.Axes.YLimMode = 'auto';
                elseif obj.SliceDimension(2)
                    % Viewing YZ Plane with X slices
                    obj.h.Axes.XLimMode = 'auto';
                else
                    % Viewing XY Plane with Z slices
                    obj.h.Axes.ZLimMode = 'auto';
                end
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function redrawImagery(obj)
            % Handle state changes that may need UI redraw
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Redraw the slice slider and indicator
                numSlices = obj.NumSlicesCurrentView;
                obj.h.Slider.Max = numSlices;
                sliderStep = max([1/(numSlices-1) 1/(numSlices-1)], [0 1]);
                obj.h.Slider.SliderStep = sliderStep;
                obj.h.Slider.Value = obj.Slice;
                obj.h.SliceEdit.String = obj.Slice;
                
                % Get the volume containing the data
                vol = obj.VolumeModel;
                
                % Get the position of the volume's slice
                sliceIdx = nan(1,3);
                sliceIdx(obj.SliceDimension) = obj.Slice;
                [x,y,z,isTranspose] = vol.getSliceXYZ(sliceIdx);
                
                % Get indices into the data for the selected slice
                indices = {':',':',':'};
                indices{obj.SliceDimension} = obj.Slice;
                
                % Get the data to display
                if any(sliceIdx > vol.DataSize)
                    c = [];
                else
                    c = squeeze( vol.ImageData(indices{:}) );
                end
                a = vol.Alpha;
                
                if isTranspose
                    c=c';
                    a=a';
                end
                
                % Update the image
                set(obj.h.Image,'XData',x,'YData',y,'ZData',z,'CData',c,'AlphaData',a);
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function create(obj)
            
            obj.hLayout.MainContainer = uicontainer(...
                'Parent',obj.hBasePanel,...
                'Units','normalized',...
                'Position',[0 0 1 1]);
            
            %--- Axes and imagery ---%
            
            obj.hLayout.AxesContainer = uicontainer(...
                'Parent',obj.hLayout.MainContainer,...
                'Units','pixels');
            
            % Create the axes
            obj.h.Axes = axes(...
                'Parent',obj.hLayout.AxesContainer,...
                'DataAspectRatio',[1 1 1],...
                'Color','none',...
                'XColor',[1 1 1] * 0.5,...
                'YColor',[1 1 1] * 0.5,...
                'ZColor',[1 1 1] * 0.5,...
                'XAxisLocation','origin',...
                'GridColor',[1 1 1] * 0.8,...
                'GridAlpha',0.25,...
                'Layer','top',... %put grid above data
                'PickableParts','all',...
                'Units','normalized',...
                'Position',[0 0 1 1]);
            axis(obj.h.Axes,'tight');
            obj.h.Axes.XAxis.Label.String = 'X';
            obj.h.Axes.YAxis.Label.String = 'Y';
            obj.h.Axes.ZAxis.Label.String = 'Z';
            
            % Specify axes interactions
            if ~verLessThan('matlab','9.5')
                disableDefaultInteractivity(obj.h.Axes);
                %obj.h.Axes.Interactions = [zoomInteraction panInteraction];
                axtoolbar(obj.h.Axes,{'export','pan','zoomin','zoomout','restoreview'});
            end
            
            % Create the image
            obj.h.Image = matlab.graphics.primitive.Surface(...
                'Parent',obj.h.Axes,...
                'XData',[0 1], ...
                'YData',[0 1], ...
                'ZData',[0 0; 0 0], ...
                'CData',[], ...
                'CDataMapping','scaled', ...
                'FaceColor','texturemap',...
                'FaceAlpha',1,...
                'PickableParts','visible',...
                'HitTest','off', ...
                'EdgeColor','none');
            
            % Use grey colormap
            colormap(obj.h.Axes,gray(256))
            
            %--- View controls ---%
            obj.h.ViewIndicator = uicontrol(...
                'Parent',obj.hLayout.MainContainer,...
                'Style','text',...
                'Units','pixels',...
                'FontSize',12,...
                'FontWeight','bold',...
                'Callback',@(h,e)onViewChanged(obj,e) );
            
            %--- Z-slice controls ---%
            obj.h.SliceEdit = uicontrol(...
                'Parent',obj.hLayout.MainContainer,...
                'Style','edit',...
                'Units','pixels',...
                'FontSize',12,...
                'Callback',@(h,e)onSliceEditChanged(obj,e) );
            
            obj.h.Slider = uicontrol(...
                'Parent',obj.hLayout.MainContainer,...
                'Style','Slider',...
                'Units','pixels',...
                'Min',1,...
                'Value',1,...
                'Callback',@(h,e)onSliceSliderChanged(obj,e) );
            
            obj.h.SliderListener = addlistener(obj.h.Slider,'Value',...
                'PostSet',@(h,e)onSliceSliderChanged(obj,e));
            
        end %function
        
        
        function onResized(obj)
            % Handle changes to container size
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Get widget dimensions
                pos = getpixelposition(obj.hLayout.MainContainer);
                w = pos(3);
                h = pos(4);
                pad = obj.Padding;
                spc = obj.Spacing;
                
                % Calculate positions
                vpopX = 1 + pad;
                vpopW = 45;
                vpopH = 25;
                vpopY = h - pad - vpopH;
                seditY = vpopY - spc - vpopH;
                sliderW = 25;
                sliderY = 1 + pad;
                sliderH = seditY - spc - sliderY;
                axesX = vpopX + sliderW + spc;
                axesW = max(w - pad - axesX, 1);
                axesH = max(h - 2*pad, 1);
                
                vpopW = max([1,vpopW]);
                vpopH = max([1,vpopH]);
                sliderH = max([1,sliderH]);
                
                % Position components
                obj.h.ViewIndicator.Position = [vpopX vpopY vpopW vpopH];
                obj.h.SliceEdit.Position = [vpopX seditY sliderW vpopH];
                obj.h.Slider.Position = [vpopX sliderY sliderW sliderH];
                obj.hLayout.AxesContainer.Position   = [axesX sliderY axesW axesH];
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onModelSet(obj)
            
            % Redraw all
            obj.redraw();
            
        end %function
        
        
        function onModelChanged(obj,evt)
            
            % Subclass may override this and choose to redraw based on the
            % event, if necessary for more complex scenarios.
            
            obj.redrawImagery();
            
        end %function
        
        
        function onStyleChanged(obj,~)
            % Handle updates to style changes - subclass may override
            
            % Ensure the construction is complete
            if obj.IsConstructed
                
                % Call superclass methods
                onStyleChanged@uiw.abstract.WidgetContainer(obj);
                
                % Label
                obj.LabelForegroundColor = obj.ForegroundColor;
                
                % Slider update
                obj.redrawImagery();
                
            end %if obj.IsConstructed
            
        end %function
        
        
        function onSliceEditChanged(obj,~)
            % Handle changes to the Slice slider
            
            % Get the new slice value
            newSlice = str2double(obj.h.SliceEdit.Value);
            
            % Try to set the new slice
            try
                obj.Slice = newSlice;
            catch
                obj.redrawSliceSelection();
                return
            end
            
            % Call callback
            evt = uiw.event.EventData('Interaction','Slice Changed',...
                'NewValue',obj.Slice);
            obj.callCallback(evt);
            
        end %function
        
        
        function onSliceSliderChanged(obj,~)
            % Handle changes to the Slice slider
            
            % Get the new slice from the slider
            obj.Slice = obj.h.Slider.Value;
            
            % Call callback
            evt = uiw.event.EventData('Interaction','Slice Changed',...
                'NewValue',obj.Slice);
            obj.callCallback(evt);
            
        end %function
        
        
        function onViewChanged(obj,evt)
            % Handle changes to the View Plane Popup
            
            % Get the changes to the value
            oldValue = obj.View;
            newValue = lower( obj.VIEWS(evt.Source.Value) );
            
            % Update the view
            obj.View = newValue;
            
            % Call callback
            evt = struct('Source', obj, ...
                'Interaction', 'View Changed', ...
                'OldValue', oldValue, ...
                'NewValue', newValue);
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
        
        function set.View(obj,value)
            obj.View = value;
            obj.redraw();
        end %function
        
        function set.ShowAxes(obj,value)
            obj.ShowAxes = value;
            obj.redraw();
        end %function
        
        function set.ShowGrid(obj,value)
            obj.ShowGrid = value;
            obj.redraw();
        end %function
        
        function set.EnableViewSelection(obj,value)
            obj.EnableViewSelection = value;
            obj.redraw();
        end %function
        
        function value = get.DataAspectRatio(obj)
            value = obj.h.Axes.DataAspectRatio;
        end %function
        function set.DataAspectRatio(obj,value)
            obj.h.Axes.DataAspectRatio = value;
        end %function
        
        function value = get.Slice(obj)
            value = max( min(obj.Slice, obj.NumSlicesCurrentView), 1 );
        end %function
        function set.Slice(obj,value)
            value = round(value);
            value = max( min(value, obj.NumSlicesCurrentView), 1); %#ok<MCSUP>
            obj.Slice = value;
            obj.redrawSliceSelection();
        end %function
        
        function value = get.SliceDimension(obj)
            value = strcmp(obj.View,{'xz','yz','xy'});
        end
        
        function value = get.NumSlicesCurrentView(obj)
            value = obj.VolumeModel.DataSize(obj.SliceDimension);
        end %function
    end %methods
    
end % classdef