classdef (Hidden) LineAnnotation < uiw.model.PointsAnnotation
    % LineAnnotation -
    %
    %
    %
    % Syntax:
    %       obj = LineAnnotation
    %       obj = LineAnnotation('Property','Value',...)
    %
    % Notes:
    %
    %
    
    % Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 224 $
    %   $Date: 2018-07-11 14:44:12 -0400 (Wed, 11 Jul 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Internal Properties
    properties (SetAccess=protected)
        SegmentLength (:,1) double %Length of each line segment
        TotalLength (1,1) double %Total length of segments
    end %properties
    
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function updateCoordinatePlaneData(obj)
            % Update slice information and the lengths of the line segments
            
            % Call superclass method
            obj.updateCoordinatePlaneData@uiw.model.PointsAnnotation();
            
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