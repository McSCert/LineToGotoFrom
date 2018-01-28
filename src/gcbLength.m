function l = gcbLength
% GCBLENGTH Return the currently selected block's length.
%
%   Inputs:
%       N/A
%
%   Outputs:
%       l   Lenght in pixels.

    pos = get_param(gcb, 'Position');
    l = pos(3) - pos(1);
end