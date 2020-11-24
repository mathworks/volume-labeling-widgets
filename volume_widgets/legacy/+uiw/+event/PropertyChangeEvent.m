classdef (Hidden) PropertyChangeEvent < event.EventData
    % PropertyChangeEvent - Event data for property changes
    % ---------------------------------------------------------------------
    % This class provides event data for a property change
    %
    % Syntax:
    %           evt = uiw.event.PropertyChangeEvent(propName,value,model)
    %

    % Copyright 2019 The MathWorks, Inc.
    %
    % Auth/Revision:
    %   MathWorks Consulting
    %   $Author: rjackey $
    %   $Revision: 51 $  $Date: 2019-05-02 13:08:04 -0400 (Thu, 02 May 2019) $
    % ---------------------------------------------------------------------

    %% Properties
    properties
        AffectedObject
        Property char
        NewValue
        Error
    end %properties


    %% Constructor / destructor
    methods
        function obj = PropertyChangeEvent(propName,value,aObj,err)
            
            obj.Property = propName;
            obj.NewValue = value;
            if nargin > 2
                obj.AffectedObject = aObj;
                if nargin > 3
                    obj.Error = err;
                end
            end

        end %constructor
    end %methods

end % classdef