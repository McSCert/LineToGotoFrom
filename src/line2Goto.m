function line2Goto(address, line, tag)
% line2Goto Convert a signal line into a goto/from connection.
%   line2Goto(A, L, T) Converts line L at address A to goto/from
%   connections with tag T, where:
%       A is the system path
%       L is the line handle
%       T is a valid variable name string
%
%   Example:
%
%   line2Goto(gcs, gcl, 'NewLine')  % converts the currently selected line in 
%                                   % the current Simulink system to goto/from
%                                   % blocks with tag 'NewLine'
    
    % Parameters - Can be changed by user
    RESIZE_BLOCK = true; % Resize blocks to accomodate tags. Can be done dynamically or to a static value
    
    % Check address argument A
    % Check that library is unlocked
    try
        assert(strcmp(get_param(bdroot(address), 'Lock'), 'off'));
    catch ME
        if strcmp(ME.identifier, 'MATLAB:assert:failed') || ... 
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            disp(['Error using ' mfilename ':' char(10) ...
                ' File is locked.'])
            return
        else
            disp(['Error using ' mfilename ':' char(10) ...
                ' Invalid address argument A.' char(10)])
            help(mfilename)
            return
        end
    end
    % Check that blocks aren't in a linked library
    try
        assert(~strcmp(get_param(address, 'LinkStatus'), 'implicit'));
    catch ME
        if strcmp(ME.identifier, 'MATLAB:assert:failed') || ... 
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            disp(['Error using ' mfilename ':' char(10) ...
                ' Cannot modify blocks within a linked library.'])
            return
        end
    end
    
    % Check line argument L
    try
        assert(~isempty(line));
        assert(ishandle(line))
        assert(strcmp(get_param(line, 'Type'), 'line'));
    catch ME
        if strcmp(ME.identifier, 'MATLAB:assert:failed') || ... 
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            disp(['Error using ' mfilename ':' char(10) ...
                ' Invalid line argument L.' char(10)])
            help(mfilename)
            return
        end
    end
    
   % Check tag argument T
   try
        assert(isvarname(tag));
    catch ME
        if strcmp(ME.identifier, 'MATLAB:assert:failed') || ... 
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            disp(['Error using ' mfilename ':' char(10) ... 
                ' Invalid goto/from tag name provided. Valid ' ...
                'identifiers start with a letter, contain no spaces or ' ...
                'special characters and are at most 63 characters long.'])
            return
        end
   end
    
    % Get the line's source and destination blocks' ports
    srcPort = get_param(line, 'SrcPortHandle');
    dstPort = get_param(line, 'DstPortHandle');
   
    % Delete signal name label
    % Note: Branched signals will all have the same name
    set_param(line, 'Name', '');
    
    % Delete line (multiple line segments in the case of branching)
    for i = 1:length(dstPort)
      delete_line(address, srcPort, dstPort(i));
    end
    
    % Add new goto/from blocks without using existing names
    % First, check that custom block library is loaded
    if ~bdIsLoaded('ChryslerLib')
        load_system('ChryslerLib');
    end
    
   numOfFroms = length(dstPort);   % To avoid recomputing
        
    % Add goto block
    num = 0;
    error = true;
    while error
		error = false;
        try 
            %newGoto = add_block('built-in/Goto', [address '/Goto' num2str(num)]);  
            newGoto = add_block('ChryslerLib/Signals/Goto', [address '/Goto' num2str(num)]);
        catch ME
            % If a block already exists with the same name
            if strcmp(ME.identifier, 'Simulink:Commands:AddBlockCantAdd')
				num = num + 1;  % Try next name
				error = true;
            end     
        end
    end
    
    % Add from block(s)
    num = 0;
    for j = 1:numOfFroms   
        error = true;
        while error
            error = false;
            try
                %newFrom(j) = add_block('built-in/From', [address '/From' num2str(num+j-1)]);
                newFrom(j) = add_block('ChryslerLib/Signals/From', [address '/From' num2str(num+j-1)]);
            catch ME
                if strcmp(ME.identifier, 'Simulink:Commands:AddBlockCantAdd')
                    num = num + 1;  % Try next name
                    error = true;
                end
            end
        end     
    end
    
    % Set block names
    set_param(newGoto, 'GotoTag', tag);
    for k = 1:numOfFroms
        set_param(newFrom(k), 'GotoTag', tag);
    end

    % Reposition blocks
	moveToPort(newGoto, srcPort, 0);
    for l = 1:numOfFroms
        moveToPort(newFrom(l), dstPort(l), 1);
    end
    
    % Lengthen blocks to accomodate tags
    if RESIZE_BLOCK
        resizeGotoFrom(newGoto);
        for m = 1:numOfFroms
            resizeGotoFrom(newFrom(m));
        end
    end
    
    % Connect blocks with signal lines 
    % Note: Should be done after block placement is done
    newGotoPort = get_param(newGoto, 'PortHandles');
    add_line(address, srcPort, newGotoPort.Inport, 'autorouting', 'on');
    
    for n = 1:numOfFroms
        newFromPort = get_param(newFrom(n), 'PortHandles');
        add_line(address, newFromPort.Outport, dstPort(n), 'autorouting', 'on');
    end
end

function moveToPort(block, port, onLeft)
%% moveToImport Move a block to the right/left of a block port
%	moveToPort(B, P, 0) Moves a block B to the right of port P

    % Parameters - Can be changed by user
    BLOCK_OFFSET = 25;	% Distance between goto/froms and the blocks they are connected to

    % Get block's current position
    blockPosition = get_param(block, 'Position');

    % Get port position
    portPosition = get_param(port, 'Position');

    % Compute block dimensions which need to be maintained during the move
    blockWidth = blockPosition(4) - blockPosition(2);
    blockLength = blockPosition(3) - blockPosition(1);

    % Compute x dimensions   
    if ~onLeft 
        newBlockPosition(1) = portPosition(1) + BLOCK_OFFSET;  % Left
        newBlockPosition(3) = portPosition(1) + blockLength + BLOCK_OFFSET;    % Right 
    else
        newBlockPosition(1) = portPosition(1) - blockLength - BLOCK_OFFSET;    % Left
        newBlockPosition(3) = portPosition(1) - BLOCK_OFFSET;  % Right
    end

    % Compute y dimensions
    newBlockPosition(2) = portPosition(2) - (blockWidth/2);    % Top
    newBlockPosition(4) = portPosition(2) + blockWidth - (blockWidth/2);   % Bottom

    set_param(block, 'Position', newBlockPosition);
end

function resizeGotoFrom(block)
%% resizeLengthGotoFrom Resize a goto/from block to fit its tag
%   resizeLengthGotoFrom(B) Resizes goto/from block B according to its tag

    % Parameters - Can be changed by user
    STATIC_RESIZE = true;   % Resize blocks to the STATIC_SIZE value. If false, blocks are dynamically resized
    STATIC_LENGTH = 150;
    STATIC_HEIGHT = 20;
    PX_PER_LETTER = 9;	% Number of pixels to allocate. On average this is sufficient 

    % Get the block information
    origBlockPosition = get_param(block, 'Position');
    origLength = origBlockPosition(3) - origBlockPosition(1);
    origHeight = origBlockPosition(4) - origBlockPosition(2);
    tag = get_param(block, 'GotoTag');
    
    newBlockPosition = origBlockPosition;
    
    newLength = origLength;
    newHeight = origHeight;
    
    if STATIC_RESIZE
        newLength = STATIC_LENGTH;
        newHeight = STATIC_HEIGHT;
    else % DYNAMIC
        newLength = length(tag) * PX_PER_LETTER;
        if newLength < origLength % Don't make it smaller
            newLength = origLength;
        end
    end

    if strcmp(get_param(block, 'BlockType'), 'Goto')
        newBlockPosition(3) = (origBlockPosition(3) - origLength) + newLength; 
    elseif strcmp(get_param(block, 'BlockType'), 'From')
        newBlockPosition(1) = (origBlockPosition(1) + origLength) - newLength;
    else
        disp('Error: Attempt to resize an unsupported block');
    end
    
    set_param(block, 'Position', newBlockPosition);
end
