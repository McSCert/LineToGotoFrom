function sels = gcl
%% gcls Get the currently selected line
%   gcls Returns a cell array with the currently selected line handle.
%   M. Bialy

    sels = find_system(gcs,'LookUnderMasks','on','Findall','on','FollowLinks','on','Type','line','Selected','on');
    if ~isempty(sels)
        sels = sels(length(sels));
    end
end