classdef (Hidden) AnnotatedIsosurfaceViewer < uiw.widget.IsosurfaceViewer & ...
        uiw.mixin.AnnotationViewer
    % AnnotatedIsosurfaceViewer -
    %
    %
    %
    % Syntax:
    %       obj = AnnotatedIsosurfaceViewer
    %       obj = AnnotatedIsosurfaceViewer('Property','Value',...)
    %
    % Notes:
    %
    %
    
    % Copyright 2018-2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 248 $  $Date: 2018-07-17 16:32:07 -0400 (Tue, 17 Jul 2018) $
    % ---------------------------------------------------------------------
    
    
    %% Constructor / destructor
    methods
        
        function obj = AnnotatedIsosurfaceViewer(varargin)
            % Construct the control
            
            % Call superclass constructor
            obj = obj@uiw.widget.IsosurfaceViewer(varargin{:});
            
            % Assign AnnotationParent axes
            obj.AnnotationParent = obj.h.Axes;
            
            % Assign clickable axes
            obj.ClickableAxes = obj.h.Axes;
            
        end %constructor
        
    end %methods
    
    
    %% Protected Methods
    methods (Access = protected)
        
        %Override
        function create(obj)
            
            % Call superclass method
            obj.create@uiw.widget.IsosurfaceViewer();
            
            % Remove default rotate interaction to enable dragging
            % annotations
            if ~verLessThan('matlab','9.5')
                obj.h.Axes.Interactions = zoomInteraction;
            end
            
        end %function
        
        
    end %methods
    
end % classdef