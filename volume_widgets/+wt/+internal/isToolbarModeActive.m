function isActive = isToolbarModeActive(buttons, modeTags)
%isToolbarModeActive - Check tagged axes toolbar modes
%   TF = isToolbarModeActive(BUTTONS,modeTags) returns true when a toolbar
%   child with a matching tag has an active value. Missing or unreadable
%   tags and values are treated as inactive for that child.
%
%   See also GET, CONTAINS

% Copyright 2026 The MathWorks, Inc.

isActive = false;
for index = 1:numel(buttons)
    button = buttons(index);
    if ~isvalid(button)
        continue
    end

    % Read individual children: heterogeneous toolbar arrays do not always
    % support dot access to properties supplied by their concrete classes.
    try
        tag = get(button, 'Tag');
    catch
        continue
    end
    validTag = (ischar(tag) && isrow(tag)) || ...
        (isstring(tag) && isscalar(tag) && ~ismissing(tag));
    if ~validTag || ~contains(string(tag), modeTags)
        continue
    end

    try
        value = get(button, 'Value');
    catch
        continue
    end
    if isa(value, 'matlab.lang.OnOffSwitchState') && isscalar(value)
        childIsActive = logical(value);
    elseif (islogical(value) || isnumeric(value)) && isscalar(value) && ...
            isreal(value) && isfinite(value) && (value == 0 || value == 1)
        childIsActive = logical(value);
    elseif (ischar(value) && isrow(value)) || ...
            (isstring(value) && isscalar(value) && ~ismissing(value))
        childIsActive = strcmp(value, 'on');
    else
        childIsActive = false;
    end
    if childIsActive
        isActive = true;
        return
    end
end
end
