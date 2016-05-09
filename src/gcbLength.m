function l = gcbLength
%% gcbLength Return the currently selected block's length
	pos = get_param(gcb,'Position');
    l = pos(3) - pos(1);
end