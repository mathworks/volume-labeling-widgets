classdef PolygonAnnotation < wt.model.LineAnnotation
    % Annotation with Y,X,Z coordinate points connected as a filled shape
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function createOne(obj,parent)
            
            obj.createOne@wt.model.LineAnnotation(parent);
            obj.Plot(2).FaceColor = 'interp';
            
        end %function        
        
        
        function [data,color,alpha] = getPlotData(obj)
            % Calculate the data to update the plot
            
            % Call the superclass method
            [data,color,alpha] = obj.getPlotData@wt.model.LineAnnotation();
            
            % Remove the NaN vertex from the Points/Line annotation, since
            % we will draw the filled shape
            data(end,:) = [];
            color(end,:) = [];
            alpha(end,:) = [];
            
            % Get the data
            % data = obj.Points;
            % color = repmat(obj.Color, size(data,1), 1);
            % alpha = repmat(obj.Alpha, size(data,1), 1);
            
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