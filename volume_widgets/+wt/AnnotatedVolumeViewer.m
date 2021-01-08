classdef AnnotatedVolumeViewer < wt.VolumeViewer & wt.mixin.AnnotationViewer
    %  Volume annotation widget with a single 2D view
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    
    %% Setup
    methods (Access = protected)
        function setup(obj)
            
            % Call superclass setup first
            obj.setup@wt.VolumeViewer();
            
            % Assign the parent for annotations
            obj.AnnotationParent = obj.Axes;
            
        end %function
    end %methods
    
    
    %% Update
    methods (Access = protected)
        function update(obj)
            
            % Call superclass update first
            obj.update@wt.VolumeViewer();
            
            % Clean-up
            obj.removeInvalidAnnotations();
            
            % Do annotations exist?
            if ~isempty(obj.AnnotationModel)
                
                % Calculate the range of the current slice
                sliceDim = obj.SliceDimension;
                currentSlice = obj.Slice3D(sliceDim);
                [~,sliceRange] = obj.VolumeModel.getSliceRange(...
                    sliceDim, currentSlice);
                
                % Apply slice filter to the annotations
                set(obj.AnnotationModel,'SliceRangeFilter',sliceRange);
                
            end %if ~isempty(obj.AnnotationModel)
            
        end %function
    end %methods
    
    
    %% Public Methods
    methods
        
        function addAnnotation(obj,aObj)
            
            % Calculate the range of the current slice
            [~,sliceRange] = obj.VolumeModel.getSliceRange(...
                obj.SliceDimension, obj.Slice);
            
            % Apply slice filter to the annotations
            set(aObj,'SliceRangeFilter',sliceRange);
            
            % Call superclass method
            obj.addAnnotation@wt.mixin.AnnotationViewer(aObj);
            
        end %function
        
    end %methods
    
    
    %% Protected Methods
    methods (Access = protected)
        
        function onAnnotationSelected(obj,evt)
            
            % Jump to the slice of the selected point
            % The annotation selected
            aObj = evt.Model;
            
            % Jump to slice of the selection and nearest vertex in 2D slice
            if ~isempty(aObj) && sum(obj.SliceDimension)==1 ...
                    && isa(aObj,'wt.model.PointsAnnotation')
                
                % Select the closest vertex in 2D space
                isSliceDim = obj.SliceDimension;
                [vertex, ~] = getNearestVertex(aObj, ...
                    evt.CurrentPoint, isSliceDim);
                
                % Jump to the nearest slice
                sliceIndex = obj.VolumeModel.getSliceIndex(vertex);
                obj.Slice = sliceIndex{isSliceDim};
                
            end %if ~isempty(obj.SelectedAnnotationModel)
            
            % Call superclass method
            obj.onAnnotationSelected@wt.mixin.AnnotationViewer(evt);
            
        end %function
        
    end %methods
    
end % classdef