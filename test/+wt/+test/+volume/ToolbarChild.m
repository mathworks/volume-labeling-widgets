classdef ToolbarChild < handle
    %ToolbarChild - Toolbar property test double

    % Copyright 2026 The MathWorks, Inc.

    properties
        Tag = 'zoomin'
        Value = true
        TagReadable = true
        ValueReadable = true
    end

    methods
        function value = get(obj, property)
            if strcmp(property, 'Tag') && ~obj.TagReadable
                error('wt:test:MissingTag', 'This child has no readable tag.');
            elseif strcmp(property, 'Value') && ~obj.ValueReadable
                error('wt:test:MissingValue', 'This child has no readable value.');
            end
            value = obj.(property);
        end
    end
end
