classdef PointsAnnotation < wt.model.BaseAnnotationModel
    % Annotation with Y,X,Z coordinate points
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    %% Public Properties
    properties (AbortSet, SetObservable)
        
        % Annotation points in [y,x,z]
        Points (:,3) double
        
        % Width of the annotation line
        LineWidth (1,1) double {mustBeNonnegative} = 2
        
    end %properties
    
    
    %% Internal Properties    
    properties (Hidden, SetAccess = protected)
        
        % Indicates all points are in the same plane
        AllInCoordinatePlane (1,3) logical 
        
        % Default editing tool for this annotation
        EditingTool = 'wt.tool.Vertices'
        
    end %properties
    
    
    
    %% Public Methods
    methods
        
        function addPoint(obj,point)
            % Adds a point to the annotation
            
            % Verify it's not a duplicate end point
            if isempty(obj.Points) || ~isequal(obj.Points(end,:),point)
                obj.Points = vertcat(obj.Points, point);
            end
            
        end %function
        
        
        function [vertex, vIdx] = getNearestVertex(obj,pos,isSliceDim)
            % Return the nearest vertex to the specified position
            % The input pos is expected in the format [y x z]
            
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
        
        function createOne(obj,parent)
        
            obj.Plot(1) = matlab.graphics.primitive.Patch(...
                'Parent',parent,...
                'PickableParts','none',...
                'LineWidth', 2,...
                'FaceColor','none',...
                'EdgeColor','interp',...
                'EdgeAlpha','interp',...
                'LineStyle','none',...
                'AlphaDataMapping','none',...
                'AlignVertexCenters','on',...
                'MarkerFaceColor','flat',...
                'UserData',obj);
            
        end %function
        
        
        function redrawOne(obj)
            
            % Return if plot is invalid
            if isempty(obj.Plot) || any(~isvalid(obj.Plot))
                return
            end
            
            % Calculate the data to update the plot
            [data,color,alpha] = obj.getPlotData();
            
            % Adjust properties based on selection/editing
            if obj.IsBeingEdited
                lineWidth = obj.LineWidth;
                marker = '+';
                markerSize = 10;
                markerEdgeColor = obj.EDITINGCOLOR;
            elseif obj.IsSelected 
                lineWidth = 2;
                marker = 'o';
                markerSize = 8;
                markerEdgeColor = obj.SELECTEDCOLOR;
            else
                lineWidth = 2;
                marker = 'o';
                markerSize = 6;
                markerEdgeColor = 'none';
            end
            
            % Update the marker plot
            set(obj.Plot(1),...
                'LineWidth',lineWidth,...
                'Marker',marker,...
                'MarkerSize',markerSize,...
                'MarkerEdgeColor',markerEdgeColor,...
                'Vertices',data(:,[2 1 3]),...
                'Faces',1:size(data,1),...
                'FaceVertexAlphaData',alpha,...
                'FaceVertexCData',color,...
                'Visible',obj.IsVisible )
            
            % Update the second plot, if one exists
            if numel(obj.Plot) > 1
                set(obj.Plot(2),...
                    'Vertices',data(:,[2 1 3]),...
                    'Faces',1:size(data,1),...
                    'FaceVertexAlphaData',alpha,...
                    'FaceVertexCData',color,...
                    'Visible',obj.IsVisible )
            end %if numel(obj.Plot) > 1
            
        end %function
        
        
        function [data,color,alpha] = getPlotData(obj)
            % Calculate the data to update the plot
            
            % Get the data
            data = obj.Points;
            color = repmat(obj.Color, size(data,1), 1);
            alpha = repmat(obj.Alpha, size(data,1), 1);
            
            % Append a NaN vertex so the face is not drawn
            data = vertcat(data, nan(1,3));
            color = vertcat(color, nan(1,3));
            alpha = vertcat(alpha, nan);
            
            % If we're in a 2D view, the viewer may have set a filter to
            % indicate the data range of the given slice. Check for that
            % condition
            rfilt = obj.SliceRangeFilter';
            sliceDim = all(isfinite(rfilt),1);
            if any(sliceDim)
                % Yes there is a slice range filter
                
                % Which points are in the current slice?
                inSlice = all(data >= rfilt(1,:) & data <= rfilt(2,:),2);
                
                % Dim color/alpha of points outside the slice
                color(~inSlice,:) = color(~inSlice,:) * 0.5;
                alpha(~inSlice,:) = alpha(~inSlice,:) * 0.5;
                
                % Adjust the position of the annotations in the slice
                % dimension to move to the plane of the imagery. Use the
                % closer edge of the range, so that it is above the
                % imagery.
                %slicePos = mean(rfilt(:,sliceDim),1);
                slicePos = rfilt(1,sliceDim);
                data(:,sliceDim) = slicePos;
                
            end
            
        end %function
        
        
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