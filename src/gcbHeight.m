function h = gcbHeight
% GCBHEIGHT Return the currently selected block's height.
%
%   Inputs:
%       N/A
%
%   Outputs:
%       h   Height in pixels.

    pos = get_param(gcb, 'Position');
    h = pos(4) - pos(2);
end