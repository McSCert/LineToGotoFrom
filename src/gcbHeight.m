function h = gcbHeight
%% gcbWidth Return the currently selected block's width
	pos = get_param(gcb, 'Position');
    h = pos(4) - pos(2);
end