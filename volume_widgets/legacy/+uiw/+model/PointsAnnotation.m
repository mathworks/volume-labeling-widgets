classdef (Hidden) PointsAnnotation < uiw.model.BaseAnnotationModel
    % PointsAnnotation -
    %
    %
    %
    % Syntax:
    %       obj = PointsAnnotation
    %       obj = PointsAnnotation('Property','Value',...)
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
    
    %% Public Properties
    properties (AbortSet, SetObservable)
        Points (:,3) double %Annotation points in [y,x,z]
        LineWidth (1,1) double {mustBeNonnegative} = 1 %Width of the annotation line
    end %properties
    
    
    %% Internal Properties
    properties (SetAccess=protected)
        AllInCoordinatePlane (1,3) logical %Indicates all points are in the same plane
        % Slice (1,3) double %If in a single slice, indicate the number
        % MinSlice (1,3) double = nan(1,3) %Lowest slice number in dataset
        % MaxSlice (1,3) double = nan(1,3) %Highest slice number in dataset
    end
    
    
    
    %% Public Methods
    methods
        
        function [vertex, vIdx] = getNearestVertex(obj,pos,isSliceDim)
            % Return the nearest vertex to the specified position
            
            % Get the points of this annotation
            points = obj.Points;
            
            % If viewing as 2D slices, ignore the slice dimension
            if nargin >= 3
                points = points(:,~isSliceDim);
                pos = pos(~isSliceDim);
            end
            
            % Calculate the distance
            distance = sqrt( sum((points - pos).^2, 2) );
            
            % Find the closest vertex (3D space, or 2D if viewing slices)
            [~,vIdx] = min(distance);
            vertex = obj.Points(vIdx,:);
            
        end %function
        
    end %methods
    
    
    %% Protected Methods
    methods (Access=protected)
        
        function updateCoordinatePlaneData(obj)
            % Update the slice information for the annotation
            
            % obj.Slice = nan(1,3);
            if isempty(obj.Points)
                obj.AllInCoordinatePlane = false(1,3);
                % obj.MinSlice = nan(1,3);
                % obj.MaxSlice = nan(1,3);
            else
                obj.AllInCoordinatePlane = all( obj.Points == obj.Points(1,:), 1 );
                % obj.Slice(obj.AllInCoordinatePlane) = obj.Points(1, obj.AllInCoordinatePlane);
                % obj.MinSlice = min(obj.Points,[],1);
                % obj.MaxSlice = max(obj.Points,[],1);
            end
            
        end %function
        
    end %methods
    
    
    %% Get/Set Methods
    methods
        
        function set.Points(obj,value)
            obj.Points = value;
            obj.updateCoordinatePlaneData();
        end
        
    end %methods
    
    
end % classdef