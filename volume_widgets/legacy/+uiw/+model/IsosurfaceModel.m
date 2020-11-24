classdef (Hidden) IsosurfaceModel < uiw.model.BaseModel
    % IsosurfaceModel - data model for an isosurface dataset
    %
    % Syntax:
    %       obj = IsosurfaceModel 
    %       obj = IsosurfaceModel('Property','Value',...)
    %
    % Notes:
    %
    %
    
    % Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting $Author: rjackey $ $Revision: 248 $  $Date: 2018-07-17 16:32:07 -0400 (Tue, 17 Jul 2018) $
    % ---------------------------------------------------------------------
    
    %% Properties
    properties (AbortSet, SetObservable)
        Name (1,:) char %Name of this isosurface
        Vertices (:,3) {mustBeNumeric} = zeros(0,3) % isosurface vertices
        Faces (:,3) {mustBeNumeric} = zeros(0,3) % isosurface faces
        Colors (:,3) {mustBeNumeric} = zeros(0,3) % isosurface color data
        Alpha (1,1) double {mustBeFinite, mustBeNonnegative, mustBeLessThanOrEqual(Alpha,1)} = 1 % isosurface alpha data
        VertexNormals (:,3) {mustBeNumeric} = zeros(0,3) % isosurface vertex normals
    end %properties
    
    properties (AbortSet)
        Tag (1,:) char %Tag identifier of this isosurface
        UserData %UserData of this isosurface
    end
    
end % classdef