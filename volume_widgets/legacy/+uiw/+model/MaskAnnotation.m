classdef (Hidden) MaskAnnotation < uiw.model.BaseAnnotationModel ...
        & uiw.mixin.HasDataGridXYZ
    % MaskAnnotation -
    %
    %
    %
    % Syntax:
    %       obj = MaskAnnotation
    %       obj = MaskAnnotation('Property','Value',...)
    %
    % Notes:
    %
    %
    
    % Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: nhowes $
    %   $Revision: 328 $
    %   $Date: 2018-10-18 16:30:45 -0400 (Thu, 18 Oct 2018) $
    % ---------------------------------------------------------------------
    
    %% Public Properties
    properties (AbortSet, SetObservable)
        Mask logical %2D or 3D Mask
        % Slice (1,3) double %If in a single slice, indicate the number
    end %properties
    
    
    %% Internal Properties
    properties (SetAccess=protected)
       AllInCoordinatePlane (1,3) logical %Indicates all points are in the same plane
    end
    
    
    properties (Dependent=true, SetAccess=protected)
        DataSize
    end %properties (dependent)
    
    
    %% Constructor / destructor
    methods
        
        function obj = MaskAnnotation( varargin )
            % Construct the object
            
            %Call superclass
            obj@uiw.model.BaseAnnotationModel( varargin{:} )
            
        end %constructor
        
    end %methods
    
    
    %% Static Methods
    methods (Static)
        
        function obj = fromVolumeModel(vObj,varargin)
            % Create a mask matching a volume model
            
            % Validate input
            validateattributes(vObj,{'uiw.model.VolumeModel'},{'scalar'})
            
            % Create the object
            % Set up the mask to match the volume
            obj = uiw.model.MaskAnnotation(...
                'XData',vObj.XData,...
                'YData',vObj.YData,...
                'ZData',vObj.ZData,...
                'Mask',false(size(vObj.ImageData)),...
                varargin{:});
            
        end %function
        
    end %methods
        
    
    
    %% Get/Set Methods
    methods
    
        function set.Mask(obj,value)
            if ~any(ndims(value)==[2 3])
                error('Expected Mask to be a 2D or 3D matrix.');
            end
            obj.Mask = value;
            obj.onDataGridChanged(); %DataChanged event
        end
        
        function value = get.DataSize(obj)
            value = size(obj.Mask);
            if numel(value)==2
                value(3) = size(obj.Mask,3);
            end
        end
    
    end %methods
    
end % classdef