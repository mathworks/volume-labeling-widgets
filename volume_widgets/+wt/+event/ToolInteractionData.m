classdef ToolInteractionData < event.EventData
    % Event data for tool interactions
    
    % Copyright 2020 The MathWorks, Inc.

    %% Properties
    properties (SetAccess = protected)
        Interaction %char
        Tool %wt.tool.BaseAnnotationTool = wt.tool.BaseAnnotationTool.empty(0);
        Model %wt.model.BaseModel
        CurrentPoint
    end %properties


    %% Constructor / destructor
    methods
        function obj = ToolInteractionData(interaction,tool,model,currentPoint)
            
            arguments
                interaction (1,1) string
                tool (1,1) wt.tool.BaseAnnotationTool
                model = tool.AnnotationModel
                currentPoint = [];
            end
            
            obj.Interaction = interaction;
            obj.Tool = tool;
%             if nargin < 3
%                 obj.Model = tool.AnnotationModel;
%             else
                obj.Model = model;
%                 if nargin >= 4
                    obj.CurrentPoint = currentPoint;
%                 end
%             end

        end %constructor
    end %methods

end % classdef