classdef IsosurfaceModel < wt.model.BaseModel
    % IsosurfaceModel - data model for an isosurface dataset
    
    % Copyright 2018-2020 The MathWorks, Inc.
    
    
    %% Properties
    properties (AbortSet, SetObservable)
        
        % Name of this isosurface
        Name (1,:) string 
        
        % Isosurface vertices
        Vertices (:,3) {mustBeNumeric} = zeros(0,3) 
        
        % Isosurface faces
        Faces (:,3) {mustBeNumeric} = zeros(0,3) 
        
        % Isosurface color data
        Colors (:,3) {mustBeNumeric} = zeros(0,3) 
        
        % Isosurface alpha data
        Alpha (1,1) double {mustBeFinite, mustBeNonnegative, mustBeLessThanOrEqual(Alpha,1)} = 1 
        
        % Isosurface vertex normals
        VertexNormals (:,3) {mustBeNumeric} = zeros(0,3) 
        
    end %properties
    
    
end % classdef