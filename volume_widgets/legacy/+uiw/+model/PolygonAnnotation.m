classdef (Hidden) PolygonAnnotation < uiw.model.LineAnnotation
    % PolygonAnnotation -
    %
    %
    %
    % Syntax:
    %       obj = PolygonAnnotation
    %       obj = PolygonAnnotation('Property','Value',...)
    %
    % Notes:
    %
    %
    
    % Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: joyeetam $
    %   $Revision: 335 $
    %   $Date: 2018-10-26 17:22:11 -0400 (Fri, 26 Oct 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function updateSegmentLength(obj)
            % Update the lengths of the line segments
            
            % Calculate lengths
            points = obj.Points;
            % For polygon, need to wrap back to the first point
            points = vertcat(points, points(1,:));
            obj.SegmentLength = sqrt(sum(diff(points,1,1).^2,2));
            obj.TotalLength = sum(obj.SegmentLength);

        end %function
        
    end %methods
    
    
end % classdef