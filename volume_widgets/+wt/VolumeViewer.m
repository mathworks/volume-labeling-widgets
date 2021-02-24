classdef VolumeViewer < wt.abstract.BaseVolumeViewer & wt.mixin.Enableable & ...
        wt.mixin.FieldColorable & wt.mixin.FontColorable
    % Volume visualization widget with a 2D view of an image stack
    
    % Copyright 2020 The MathWorks, Inc.
    
    
    %% Events
    events (HasCallbackProperty)
        
        % View or slice changes
        ViewChanged
        
    end %events
    
    
    
    %% Properties
    properties (AbortSet, SetObservable)
        
        % Current view plane
        View (1,1) wt.enum.ViewAxis = wt.enum.ViewAxis.xy
        
        % Current Slice to display
        Slice3D (1,3) double {mustBeInteger,mustBeFinite,mustBePositive} = [1 1 1]
        
    end %properties
    
    
    properties (Dependent, AbortSet, SetObservable)
        
        % Current Slice to display
        Slice (1,1) double {mustBeInteger,mustBeFinite,mustBePositive} = 1
        
    end %properties
    
    
    properties (Dependent, SetAccess=immutable)
        
        % Logical array giving dimension of slices into the 2D view [Y X Z]
        SliceDimension 
        
    end %properties
    
    
    
    %% Internal Properties
    properties (Transient, Hidden, SetAccess = protected)
        
        % The image surface
        Image matlab.graphics.primitive.Surface
        
        % The selector/indicator for the view direction
        ViewIndicator matlab.graphics.Graphics
        
        % The numeric spinner for selecting slice
        SliceSpinner matlab.ui.control.Spinner
        
        % The slider for selecting slice
        SliceSlider matlab.ui.control.Slider
        
    end %properties
    
    
    
    %% Setup
    methods (Access = protected)
        function setup(obj)
            
            % Call superclass setup first
            obj.setup@wt.abstract.BaseVolumeViewer();
            
            % Set default size
            obj.Position = [10 10 400 400];

            % Configure Grid
            obj.Grid.RowHeight = {25,25,'1x'};
            obj.Grid.ColumnWidth = {55,'1x'};
            obj.AxesContainer.Layout.Column = 2;
            obj.AxesContainer.Layout.Row = [1 3]; 
            
            % Customize axes toolbar
            axtoolbar(obj.Axes,{'export','zoomin','zoomout','pan','restoreview'});
            
            %--- View controls ---%
            obj.ViewIndicator = uidropdown(obj.Grid);
            obj.ViewIndicator.Layout.Column = 1;
            obj.ViewIndicator.Layout.Row = 1;
            viewChoices = enumeration('wt.enum.ViewAxis');
            obj.ViewIndicator.Items = upper(string(viewChoices));
            obj.ViewIndicator.ItemsData = viewChoices;
            obj.ViewIndicator.FontSize = 16;
            obj.ViewIndicator.FontWeight = 'bold';
            obj.ViewIndicator.ValueChangedFcn = @(h,e)onViewChanged(obj,e);
            
            %--- Slice controls ---%
            obj.SliceSpinner = uispinner(obj.Grid);
            obj.SliceSpinner.Layout.Column = 1;
            obj.SliceSpinner.Layout.Row = 2;
            obj.SliceSpinner.FontSize = 14;
            obj.SliceSpinner.RoundFractionalValues = "on";
            obj.SliceSpinner.ValueChangingFcn = @(h,e)onSliceSpinnerChanged(obj,e);
            
            obj.SliceSlider = uislider(obj.Grid);
            obj.SliceSlider.Layout.Column = 1;
            obj.SliceSlider.Layout.Row = 3;
            obj.SliceSlider.Limits = [0 1];
            obj.SliceSlider.MinorTicks = [];
            obj.SliceSlider.Orientation = 'vertical';
            obj.SliceSlider.ValueChangingFcn = @(h,e)onSliceSliderChanged(obj,e);         
            
            % Create the image
            obj.Image = obj.createImagePlot();
            
            % Update the internal component lists
            obj.FieldColorableComponents = [obj.ViewIndicator, obj.SliceSpinner];
            obj.FontColorableComponents = [obj.ViewIndicator, obj.SliceSlider, obj.SliceSpinner];
            obj.EnableableComponents = [obj.ViewIndicator, obj.SliceSlider, obj.SliceSpinner];
            
            % Change defaults
            obj.FieldColor = obj.BackgroundColor;
            obj.FontColor = [1 1 1] * 0.6;
             
        end %function
    end %methods
    
    
    %% Update
    methods (Access = protected)
        function update(obj)
            
            % Get the slice information
            sliceDim = obj.SliceDimension;
            currentSlice = obj.Slice3D(sliceDim);
            
            numSlicesCurrentView = max(obj.VolumeModel.DataSize(sliceDim), 1.01);
            
            % Update view indicator
            if isa(obj.ViewIndicator,'matlab.ui.control.Label')
                wt.utility.fastSet(obj.ViewIndicator,'Text',upper(string(obj.View)));
            else
                wt.utility.fastSet(obj.ViewIndicator,'Value',obj.View);
            end
            
            % Update slice edit field
            wt.utility.fastSet(obj.SliceSpinner,...
                'Limits',[1 numSlicesCurrentView],...
                'Value',currentSlice);
            
            % Update slice slider and indicator
            wt.utility.fastSet(obj.SliceSlider,...
                'Limits',[1 numSlicesCurrentView],...
                'Value',currentSlice);
            
            % Get the position of the volume's slice
            sliceIdx = nan(1,3);
            sliceIdx(sliceDim) = currentSlice;
            [x,y,z,isTranspose] = obj.VolumeModel.getSliceXYZ(sliceIdx);
            
            % Get indices into the data for the selected slice
            indices = {':',':',':'};
            indices{sliceDim} = currentSlice;
            
            % Get the data to display
            if any(sliceIdx' > obj.VolumeModel.DataSize)
                c = [];
            else
                c = squeeze( obj.VolumeModel.ImageData(indices{:}) );
            end
            a = obj.VolumeModel.Alpha;
            
            if isTranspose
                c=c';
                a=a';
            end
            
            % Update the image
            set(obj.Image,'XData',x,'YData',y,'ZData',z,'CData',c,'FaceAlpha',a);
            
            % Which dimension are we looking at? Don't let panning turn off
            % automatic axes limits on the slice axis
            if sliceDim(2)
                % Viewing YZ Plane with X slices
                wt.utility.fastSet(obj.Axes,'XLimMode','auto');
                viewValue = [-90 0];
            elseif sliceDim(3)
                % Viewing XY Plane with Z slices
                wt.utility.fastSet(obj.Axes,'ZLimMode','auto');
                viewValue = [0 -90];
            else
                % Viewing XZ Plane with Y slices
                wt.utility.fastSet(obj.Axes,'YLimMode','auto');
                viewValue = [0 0];
            end
            wt.utility.fastSet(obj.Axes,'View',viewValue);
            
        end %function
    end %methods
    
    
    
    %% Callbacks
    methods (Access = protected)
        
        function onSliceSpinnerChanged(obj,evt)
            % Handle changes to the Slice spinner
            
            % Update the view
            obj.Slice = evt.Value;
            
            % Notify event
            evtOut = wt.eventdata.PropertyChangedData('Slice',evt);
            obj.notify('ViewChanged',evtOut)
            
        end %function
        
        
        function onSliceSliderChanged(obj,evt)
            % Handle changes to the Slice slider
            
            % First, round the slider value to an integer
            newValue = round(evt.Value);
            
            % Is it different from the current value?
            if newValue ~= obj.Slice
                
                % Update the view
                obj.Slice = newValue;
                
                % Notify event
                evtOut = wt.eventdata.PropertyChangedData('Slice',evt);
                obj.notify('ViewChanged',evtOut)
                
            end %if newValue ~= obj.Slice
            
        end %function
        
        
        function onViewChanged(obj,evt)
            % Handle changes to the View dropdown
            
            % Update the view
            obj.View = evt.Value;
            
            % Notify event
            evtOut = wt.eventdata.PropertyChangedData('View',evt);
            obj.notify('ViewChanged',evtOut)
            
        end %function
        
    end %methods
    
    
    
    %% Public Methods
    methods
        
        function disableViewControl(obj)
            % Changes the view control dropdown to display only
            
            % Remove the dropdown
            delete(obj.ViewIndicator);
            
            % Add a label view indicator
            obj.ViewIndicator = uilabel(obj.Grid);
            obj.ViewIndicator.Layout.Column = 1;
            obj.ViewIndicator.Layout.Row = 1;
            obj.ViewIndicator.FontSize = 16;
            obj.ViewIndicator.FontWeight = 'bold';
            
            % Update the internal component lists
            obj.BackgroundColorableComponents = [obj.AxesContainer, obj.ViewIndicator];
            obj.FieldColorableComponents = [obj.SliceSpinner];
            obj.FontColorableComponents = [obj.ViewIndicator, obj.SliceSlider, obj.SliceSpinner];
            obj.EnableableComponents = [obj.SliceSlider, obj.SliceSpinner];
            
        end %function
        
        
        function disableAxesTools(obj)
            % Disable the axes toolbar
            
            obj.Axes.Toolbar.Visible = 'off';
            
        end %function
        
    end %methods
    
    
    
    %% Get/Set Methods
    methods
        
        function value = get.SliceDimension(obj)
            value = obj.View == ["xz" "yz" "xy"];
        end
        
        function value = get.Slice(obj)
            sDim = obj.SliceDimension;
            value = obj.Slice3D(sDim);
        end
        
        function set.Slice(obj,value)
            sDim = obj.SliceDimension;
            obj.Slice3D(sDim) = value;
        end
        
        function value = get.Slice3D(obj)
            value = min(obj.Slice3D, obj.VolumeModel.DataSize');
            value(value<1) = 1;
        end 
        
    end %methods
    
end % classdef