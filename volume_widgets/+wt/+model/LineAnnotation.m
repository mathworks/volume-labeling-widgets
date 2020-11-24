classdef LineAnnotation < wt.model.PointsAnnotation
    % Annotation with Y,X,Z coordinate points connected with a line
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    
    %% Internal Properties
    properties (SetAccess=protected)
        
        % Length of each line segment
        SegmentLength (:,1) double
        
        % Total length of segments
        TotalLength (1,1) double
        
    end %properties
    
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function createOne(obj,parent)
            
            obj.createOne@wt.model.PointsAnnotation(parent);
            set(obj.Plot,'LineStyle','-');
            
        end %function
        
        
        function updateCoordinatePlaneData(obj)
            % Update slice information and the lengths of the line segments
            
            % Call superclass method
            obj.updateCoordinatePlaneData@wt.model.PointsAnnotation();
            
            % Calculate lengths
            obj.updateSegmentLength();
            
        end %function
        
        
        function updateSegmentLength(obj)
            % Update the lengths of the line segments
            
            % Calculate lengths
            points = obj.Points;
            obj.SegmentLength = sqrt(sum(diff(points,1,1).^2,2));
            obj.TotalLength = sum(obj.SegmentLength);
            
        end %function
        
    end %methods
    
end % classdef