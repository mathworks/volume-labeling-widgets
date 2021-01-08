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
        
        function selectAnnotation(obj, aObjIn, clickPoint)
            % Select annotation by index or object
            
            %RAJ - review & clean up
            
            % Call superclass method
            obj.selectAnnotation@wt.mixin.AnnotationViewer(aObjIn);
            
            % The annotation selected
            aObj = obj.SelectedAnnotationModel;
                
            % Jump to slice of the selection and nearest vertex in 2D slice
            if nargin>=3 && ~isempty(aObj) && sum(obj.SliceDimension)==1 ...
                    && isa(aObj,'wt.model.PointsAnnotation')
                
                % Select the closest vertex in 2D space
                isSliceDim = obj.SliceDimension;
                [vertex, ~] = getNearestVertex(aObj, ...
                    clickPoint([2 1 3]), isSliceDim);
                
                % Store the selected vertex index
                %obj.SelectedVertex = vIdx;
                
                % Jump to the nearest slice
                sliceIndex = obj.VolumeModel.getSliceIndex(vertex);
                obj.Slice = sliceIndex{isSliceDim};
                
            else
                % No vertex was selected
                %obj.SelectedVertex = [];
                
            end %if ~isempty(obj.SelectedAnnotationModel)
            
        end %function
        
        
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

end % classdef