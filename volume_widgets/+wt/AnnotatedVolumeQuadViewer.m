classdef AnnotatedVolumeQuadViewer < wt.AnnotatedVolumeViewer
    % Volume annotation widget with 2D views from 3 sides plus 3D slice planes
    
    % Copyright 2020-2021 The MathWorks, Inc.
    
    
    %% Internal Properties
    properties (Transient, SetAccess = protected)
        
        % Slice Plane View
        SliceView wt.SlicePlaneViewer
        
        % Top 2D Slice View
        TopView wt.VolumeViewer
        
        % Side 2D Slice View
        SideView wt.VolumeViewer
        
        % Listener to Side/Top view slice changes
        SliceChangedListener event.listener 
        
    end %properties
    
    
    properties (Constant, Access = protected)
        VIEWORDER = ["xy","xz","yz"];
        SLICEORDER = [3,1,2];
    end
    
    
    %% Setup
    methods (Access = protected)
        function setup(obj)
            
            % Create additional viewers
            % Do this before superclass setup because superclass it will
            % call onModelSet, and we need to be able to set the
            % VolumeModel property in these viewers at that time.
            obj.SliceView = wt.SlicePlaneViewer('Parent',[]);
            obj.TopView = wt.VolumeViewer('Parent',[]);
            obj.SideView = wt.VolumeViewer('Parent',[]);
            
            % Disable the view controls in top/side views
            obj.TopView.disableViewControl();
            obj.SideView.disableViewControl();
            obj.TopView.disableAxesTools();
            obj.SideView.disableAxesTools();
            
            % Call superclass setup
            obj.setup@wt.AnnotatedVolumeViewer();

            % Configure Grid
            obj.Grid.ColumnWidth = {55,'3x','1x'};
            obj.Grid.RowHeight = {25,25,'1x','1x','1x'};
            
            % Place new viewers in grid
            obj.SliceView.Parent = obj.Grid;
            obj.TopView.Parent = obj.Grid;
            obj.SideView.Parent = obj.Grid;
            
            % Adjust grid positions
            obj.SliceSlider.Layout.Row = [3 5];
            obj.AxesContainer.Layout.Row = [1 5];
            obj.SliceView.Layout.Column = 3;
            obj.SliceView.Layout.Row = [1 3];
            obj.TopView.Layout.Column = 3;
            obj.TopView.Layout.Row = 4;
            obj.SideView.Layout.Column = 3;
            obj.SideView.Layout.Row = 5;
            
            % Listen to changes in Side/Top view Slice changes
            obj.SliceChangedListener = event.listener([obj.TopView obj.SideView],...
                'ViewChanged',@(h,e)onTopSideViewSliceChanged(obj,e) );
            
        end %function
    end %methods
    
    
    %% Update
    methods (Access = protected)
        function update(obj)
            
            % Call superclass update first
            obj.update@wt.AnnotatedVolumeViewer();
            
            % What view and slice belongs in each volume viewer?
            idxView = find(obj.View == obj.VIEWORDER,1);
            order = circshift(obj.VIEWORDER, 1 - idxView);
            sIdx = circshift(obj.SLICEORDER, 1 - idxView);
            
            % Set the views first (MainView is master)
            obj.TopView.View = order{2};
            obj.SideView.View = order{3};
            
            % Update the slice in each view
            obj.Slice = obj.Slice3D(sIdx(1));
            obj.SliceView.Slice = obj.Slice3D;
            obj.TopView.Slice = obj.Slice3D(sIdx(2));
            obj.SideView.Slice = obj.Slice3D(sIdx(3));
            
        end %function
    end %methods
    
    
    
    %% Callbacks
    methods (Access = protected)
        
        function onModelSet(obj)
            
            % Update volume in subcomponents
            obj.SliceView.VolumeModel = obj.VolumeModel;
            obj.TopView.VolumeModel = obj.VolumeModel;
            obj.SideView.VolumeModel = obj.VolumeModel;
            
            % Call superclass method
            obj.onModelSet@wt.abstract.BaseVolumeViewer();
            
        end %function
        
        
        function onTopSideViewSliceChanged(obj,evt)
            
            % Update the Slice3D value for the dimension that was changed
            obj.Slice3D(evt.Source.SliceDimension) = evt.Source.Slice;
            
        end %function
        
    end %methods
    
    
end % classdef