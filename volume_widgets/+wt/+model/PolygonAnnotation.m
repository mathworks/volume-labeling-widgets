classdef PolygonAnnotation < wt.model.LineAnnotation
    % Annotation with Y,X,Z coordinate points connected as a filled shape
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function createOne(obj,parent)
            
            obj.createOne@wt.model.PointsAnnotation(parent);
            set(obj.Plot,...
                'FaceColor','interp',...
                'FaceAlpha','interp',...
                'LineStyle','-');
            
        end %function
        
        
        function [data,color,alpha] = getPlotData(obj)
            % Calculate the data to update the plot
            
            % Get the data
            data = obj.Points;
            color = repmat(obj.Color, size(data,1), 1);
            alpha = repmat(obj.Alpha, size(data,1), 1);
            
        end %function
        
        
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