function val = getLine2GotoConfig(parameter, default)
%% getLine2GotoConfig Get a parameter from the tool configuration file
%   getLine2GotoConfig(P, D) Returns the value of parameter P, or D if not found
    val = default;
    filePath = mfilename('fullpath');
    name = mfilename;
    filePath = filePath(1:end-length(name));
    fileName = [filePath 'config.txt'];
    file = fopen(fileName);
    line = fgetl(file);
   
    paramPattern = ['^' parameter  ':[ ]*[0-9]+'];

    while ischar(line)
        match = regexp(line, paramPattern, 'match');
        if ~isempty(match)
            val = match{1}; % Get first occurrance
            val = str2num(strrep(val, [parameter ':'], '')); % Strip parameter
            break
        end
        line = fgetl(file);
    end
    fclose(file);
end