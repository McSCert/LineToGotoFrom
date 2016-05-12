function goto2Line(address, blocks)
% goto2Line Convert selected local goto/from block connections into signal lines.
%   goto2Line(A, B) Converts goto/from blocks B at address A into signal
%   lines, where:
%       A is the Simulink system path
%       B is a cell array of goto/from block path names
%
%   Example:
%
%   goto2Line(gcs, gcbs)        % converts the currently selected blocks in 
%                               % the current Simulink system
%
%   goto2Line(gcs, {gcb})       % converts the currently selected block in 
%                               % the current Simulink system

    % Parameters - Can be changed by user
    DRAW_DIRECT = true;     % false = route line around blocks
                            % true = route line using diagonal lines
    
    % Check address argument A
	% Check model at address is open
    try
       assert(bdIsLoaded(address));
    catch
        disp(['Error using ' mfilename ':' char(10) ...
            ' Invalid address argument A. Model may not be loaded or name is invalid.' char(10)])
        help(mfilename)
        return
    end
    
    % Check that library is unlocked
    try
        assert(strcmp(get_param(bdroot(address), 'Lock'), 'off'));
    catch ME
        if strcmp(ME.identifier, 'MATLAB:assert:failed') || ... 
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            disp(['Error using ' mfilename ':' char(10) ...
                ' File is locked.'])
            return
        end
    end
    % Check that blocks aren't in a linked library
    try
        assert(strcmp(get_param(address, 'LinkStatus'), 'none') || ...
        strcmp(get_param(address, 'LinkStatus'), 'resolved'));
    catch ME
        if strcmp(ME.identifier, 'MATLAB:assert:failed') || ... 
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            disp(['Error using ' mfilename ':' char(10) ...
                ' Cannot modify blocks within a linked library.'])
            return
        end
    end

    % Check blocks argument B
    tagsToConnect = {};
    % For each selected block
    for x = 1:length(blocks)
        % Get its goto tag
        try
            tag = get_param(blocks{x}, 'GotoTag');
        catch ME
            if strcmp(ME.identifier, 'Simulink:Commands:ParamUnknown') 
                % If it doesn't have one, then wrong block type
                disp(['Error using ' mfilename ':' char(10) ...
                ' A selected block is not a goto/from.'])
                return
            else
                disp(['Error using ' mfilename ':' char(10) ...
                ' Invalid block argument B.' char(10)])
                help(mfilename)
                return
            end
        end
        % Check that visibility of goto/from is local
        if strcmp(get_param(blocks{x}, 'TagVisibility'), 'local')
            tagsToConnect{end+1} = tag; % Append to list
        else
            disp(['Error using ' mfilename ':' char(10) ...
                ' A selected goto/from does not have a local scope.'])
        end
    end

    % Filter out multiples of tags
    % e.g. if multiple froms of the same tag were selected
    % e.g. if both goto/from blocks in pair are selected
    tagsToConnect = unique(tagsToConnect);  % Tags of blocks to connect

    % For each tag
    for y = 1:length(tagsToConnect)
        % Get the goto corresponding to the tag
        gotos = find_system(address, 'SearchDepth', 1, 'BlockType', 'Goto', 'GotoTag', tagsToConnect{y});
        if isempty(gotos)
            disp(['Error using ' mfilename ':' char(10) ...
            ' From block ', tagsToConnect{y} , ' has no local matching goto block.'])
            continue
        end

        % Get the from(s) corresponding to the tag
        froms = find_system(address, 'SearchDepth', 1, 'BlockType', 'From', 'GotoTag', tagsToConnect{y});
        if isempty(froms)
            disp(['Error using ' mfilename ':' char(10) ...
            ' Goto block ', tagsToConnect{y} , ' has no local matching from blocks.'])
            continue
        end

        % Find what block the goto is connected to
        connections = get_param(gotos, 'PortConnectivity');
        gotoSrcBlock = connections{1}.SrcBlock;
        gotoSrcPort = connections{1}.SrcPort;

        % Find which port needs to be connected with a line
        lineStartPort = get_param(gotoSrcBlock, 'PortHandles');
        lineStartPort = lineStartPort.Outport(1 + gotoSrcPort);

        % Find endpoint of the signal line which needs deleting
        gotoPort = get_param(gotos, 'PortHandles');
        gotoPort = gotoPort{1}.Inport(1);

        % Delete signal line and goto
        delete_line(address, lineStartPort, gotoPort)
        delete_block(gotos);

        % For each from
        for z = 1:length(froms)
            % Find what block the from is connected to
            connections = get_param(froms{z}, 'PortConnectivity');
            fromDstBlock = connections(1).DstBlock;
            fromDstPort = connections(1).DstPort;

            % Find which port needs to be connected with a line
            lineEndPort = get_param(fromDstBlock, 'PortHandles');
            lineEndPort = lineEndPort.Inport(1 + fromDstPort);

            % Find starting point of the signal line which needs deleting
            fromPort = get_param(froms{z}, 'PortHandles');
            fromPort = fromPort(1).Outport(1);

            % Delete signal line and from
            delete_line(address, fromPort, lineEndPort)
            delete_block(froms{z})

            % Connect block ports with line
            if DRAW_DIRECT
                add_line(address, lineStartPort, lineEndPort);
            else
                add_line(address, lineStartPort, lineEndPort, 'autorouting', 'on');
            end
        end
    end
end
