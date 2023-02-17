classdef PlaneAnnotation < wt.model.PointsAnnotation
    %PLANEANNOTATION Annotation with Y,X,Z coordinate points to
    %define a plane
    
    % Copyright 2018-2023 The MathWorks, Inc.
    
    
    %% Public Properties
    properties (AbortSet, SetObservable)
        
        % 3 or 4 Annotation points [y,x,z] to define a plane
        MaxPoint (1,1) double {mustBeMember(MaxPoint,[3 4])} = 3 
        
        % Method of determining the plane from the points
        Method (1,1) string {mustBeMember(Method, ["deterministic" "svd"])} = "deterministic"   
        
        % Maximum display distance boundaries of the plane (use smaller values for a finite representation) 
        Bounds (2,2) double = [-1e6 1e6; -1e6 1e6];

    end %properties
    

    
    %% Internal Properties 
    properties (Hidden, SetAccess = protected)
        
        % Equation of plane solved for z on bounds corner points 
        %n(1)*x + n(2)*y + n(3)*z + d == 0;
        ZOfPlane = @(x,y,n,d)( n(1).*x + n(2).*y + d )./-n(3); 
            
    end %properties
        
    
    
    %% Public Methods 
    methods
        
        function addPoint(obj,point)
            % Adds a point to the annotation
            
            % Is there space for another point.
            isValidNumel = size( obj.Points,1 ) < obj.MaxPoint; 
            
            % Is this new point a duplicate?
            isDupe = any(all(obj.Points == point,2));
            
            % We can only add up to 4 points!
            if isValidNumel && ~isDupe
                
                if all( isnan(obj.Points) )
                    obj.Points = point;
                else
                    obj.Points = [obj.Points; point];
                end %if all
                
            end %if isValid...
            
            % If there are more than 3 points we'll use svd to fit a plane
            if size(obj.Points,1) > 3
                obj.Method = "svd";
            else
                obj.Method = "deterministic";
            end %if
            
        end %function 
        
        function result = table(obj)
            % Control Points
            
            if isempty(obj)
                result = table.empty(0,4);
            else
                nPoints = size(obj.Points, 1);
                iD      = transpose(string(1:obj.MaxPoint));
                value   = nan(obj.MaxPoint, 3);
                
                value(1:nPoints, :) = obj.Points;
                
                %Display as [X,Y,Z]
                result = table(iD, value(:,2), value(:,1), value(:,3), ...
                    'VariableNames', ["iD" "X" "Y" "Z"] );
            end
            
        end %function
        
        function [normalvector, planarconstant] = planarMetrics( obj ) 
            %planarMetrics Calculate (1) vector normal to plane as XYZ and
            %(2) planar constant. If # points = 3, calculation is
            %deterministic, if # points = 4, calculation is svd.  
            
            %Points defining a plane
            P = obj.Points(:,[2 1 3]);
            
            %If there are fewer than max points, skip planar calculations
            if size(P,1) < obj.MaxPoint 
                normalvector = [ NaN NaN NaN ];
                planarconstant = NaN;
            else
                
                %Calculate
                switch obj.Method
                    case "deterministic"
                        
                        %Find vectors in plane
                        V1 = P(1,:) - P(2,:);
                        V2 = P(2,:) - P(3,:);
                        
                        % Find normal vector
                        normalvector = cross(V1, V2);
                        
                        normalvector = normalvector./norm(normalvector);
                        
                        % Solve for planar constant
                        planarconstant = -dot(P(1,:), normalvector ); %NCH moved the -minus out of the first element
                        
                    case "svd"
                        
                        % Vector mean of points
                        muP = mean(P,1);
                        
                        % Singular value decomposition of points - vector mean
                        [~, S, V] = svd(P - muP, 0);
                        
                        % Index the normal vector
                        [~, index] = min( diag(S) );
                        
                        % Find normal vector
                        normalvector = V(:, index);
                        normalvector = normalvector(:)';
                        
                        % Solve for planar constant
                        planarconstant = -dot(muP, normalvector );
                        
                end %switch
                
            end %if size(P...  
            
        end %function 
 
    end %methods
    
    %% Protected Methods
    methods (Access=protected)
        function createOne(obj,parent)

            obj.createOne@wt.model.PointsAnnotation(parent);
            
            %Plane defined by point annotation
            obj.Plot(2) = matlab.graphics.primitive.Patch(...
                'Parent',parent,...
                'PickableParts','none',...
                'Marker','none',...
                'FaceColor',obj.Color,...
                'EdgeColor','none',...
                'LineStyle','none',...
                'AlphaDataMapping','none',... 
                'AlignVertexCenters','on',...
                'XLimInclude','off',...
                'YLimInclude','off',...
                'ZLimInclude','off',...
                'UserData',obj);
                   
        end %function
        
 
        function redrawOne(obj)
        
            obj.redrawOne@wt.model.PointsAnnotation();

            % Toggle control points visibility
            obj.Plot(1).Visible = obj.IsVisible && ...
                (obj.IsBeingEdited || obj.IsSelected);
            
            % Calculate planar metrics 
            [normalvector, planarconstant] = obj.planarMetrics; 
            
            % Grid corners for plane calc
            [X,Y] = meshgrid( ...
                obj.Bounds(1,:), ...
                obj.Bounds(2,:)...
                );
            
            % Solve for z-value on grid corners
            Z = obj.ZOfPlane( X, Y, normalvector, planarconstant );
            
            % Reorder 
            reOrder = [1 2 4 3];
            planedata = [X(reOrder(:)) Y(reOrder(:)) Z(reOrder(:))];

           %Update plane   
            set(obj.Plot(2),...
                'Vertices',planedata,...
                'Faces',1:numel(Z),...
                'FaceColor',obj.Color, ...
                'FaceAlpha', obj.Alpha, ...
                'Visible',obj.IsVisible)
            
        end %function 
        
    end %methods
    
end %classdef


            