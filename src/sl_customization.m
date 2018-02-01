%% Register custom menu function to beginning of Simulink Editor's context menu
function sl_customization(cm)
	cm.addCustomMenuFcn('Simulink:PreContextMenu', @getMcMasterTool);
end

%% Define custom menu function
function schemaFcns = getMcMasterTool(callbackInfo)
    schemaFcns = {};
    if (strcmp(get_param(gcb, 'BlockType'), 'Goto') || ...
        strcmp(get_param(gcb, 'BlockType'), 'From')) && ...
        strcmp(get_param(gcb, 'Selected'), 'on')
        schemaFcns{end+1} = @Goto2LineSchema;
    elseif ~isempty(gcls)
        schemaFcns{end+1} = @Line2GotoSchema;
    end
end

%% Define first action
function schema = Goto2LineSchema(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Goto/Froms to Line';
    schema.userdata = 'goto2Line';
    schema.callback = @goto2LineCallback;
end

function goto2LineCallback(callbackInfo)
    goto2Line(gcs, gcbs);
end

%% Define second action
function schema = Line2GotoSchema(callbackInfo)
    schema = sl_action_schema;
    schema.label = 'Line to Goto/Froms';
    schema.userdata = 'line2Goto';
    schema.callback = @line2GotoCallback;
end

function line2GotoCallback(callbackInfo)
    allLines = gcls;

    % Get lines that are trunk lines (Important for branches)
    trunkLines = {};
    for i = 1:length(allLines)
        if strcmp(get_param(allLines(i), 'SegmentType'),'trunk')
            trunkLines{end+1} = allLines(i);
        end
    end

    % Check that library is unlocked
    try
        assert(strcmp(get_param(bdroot(get_param(trunkLines{1}, 'Parent')), 'Lock'), 'off'));
    catch ME
        if strcmp(ME.identifier, 'MATLAB:assert:failed') || ...
                strcmp(ME.identifier, 'MATLAB:assertion:failed')
            error('File is locked.')
            return
        end
    end

    % For each trunk line
	for j = 1:length(trunkLines)
        % Get signal name
        line = trunkLines{j};
        signalName = get_param(line, 'Name');

        % Get propogated signal name
        signalSrcPort = get_param(line, 'SrcPortHandle');
        propagated_signalName = get_param(signalSrcPort, 'PropagatedSignals');

        % Use signal name when available. If you can't, use the propagated
        % signal name. If you can't, prompt the user to enter a new name.
        if ~isempty(signalName) && isvarname(signalName)
            % Use signal name
        elseif isempty(signalName) && isempty(propagated_signalName)
            signalName = gotoGUI;
        elseif ~isempty(signalName) && ~isvarname(signalName) && isempty(propagated_signalName)
             warning(['Signal name "', signalName, ...
                 '" is not a valid name. Prompting user for new name.'])
            signalName = gotoGUI;
        elseif isempty(signalName) && (~isempty(propagated_signalName) ...
                && isvarname(propagated_signalName))
            signalName = propagated_signalName;
        elseif isempty(signalName) && (~isempty(propagated_signalName) ...
                && ~isvarname(propagated_signalName))
             warning(['Propagated signal name "', propagated_signalName, ...
                 '" is not a valid name. Prompting user for new name.'])
            signalName = gotoGUI;
        elseif (~isempty(signalName) && ~isvarname(signalName)) ...
                && (~isempty(propagated_signalName) ...
                && isvarname(propagated_signalName))
            warning(['Signal name "', signalName, ...
                '" is not a valid name. Using propagated signal name instead.'])
            signalName = propagated_signalName;
        elseif (~isempty(signalName) && ~isvarname(signalName)) ...
                && (~isempty(propagated_signalName) ...
                && ~isvarname(propagated_signalName))
            warning(['Signal name "', signalName , '" and propagated signal name "', ...
                propagated_signalName, '" are not valid variable names. Prompting user for new name.'])
            signalName = gotoGUI;
        end

        if isempty(signalName)   % GUI gialog was closed, so stop transformation
            return
        else    % Valid name was provided (GUI checks it is valid)
            % Check for conflicts with existing gotos with the same name
            conflictLocalGotos = find_system(gcs, 'SearchDepth', 1, 'BlockType', 'Goto', 'GotoTag', signalName);

            conflictsGlobalGotos = find_system(bdroot, 'BlockType', 'Goto', 'TagVisibility', 'global', 'GotoTag', signalName);

            allScopedGotos = find_system(bdroot, 'BlockType', 'Goto', 'TagVisibility', 'scoped', 'GotoTag', signalName);
            belowScopedGotos = find_system(gcs, 'BlockType', 'Goto', 'TagVisibility', 'scoped', 'GotoTag', signalName);
            conflictsScopedGotos = setdiff(allScopedGotos, belowScopedGotos);

            % 1) Check for local conflicts
            if ~isempty(conflictLocalGotos)
                answer = questdlg(['A local goto named "' signalName '" already exists.' ...
                    char(10) 'Proceed with transformation?'], ...
                    'Line to Goto/Froms: Warning', ...
                    'Yes', 'Change Name', 'No', 'Change Name');
                switch answer
                    case 'Yes'
                        % Use the provided tag
                    case 'Change Name'
                        % Try again
                        signalName = gotoGUI;
                    case 'No'
                        % Skip this line, continue with the rest
                        set_param(line, 'Selected', 'off');
                        continue
                     case ''
                        % Skip this line, continue with the rest
                        set_param(line, 'Selected', 'off');
                        continue
                end
            % 2) Check for global goto (anywhere in the model) conflicts
            elseif ~isempty(conflictsGlobalGotos)
                answer = questdlg(['A global goto named "' signalName '" already exists.' ...
                    char(10) ' Proceed with transformation?'], ...
                    'Line to Goto/Froms: Warning', ...
                    'Yes', 'Change Name', 'No', 'Change Name');
                switch answer
                    case 'Yes'
                        % Use the provided tag
                    case 'Change Name'
                        % Try again
                        signalName = gotoGUI;
                    case 'No'
                        % Skip this line, continue with the rest
                        set_param(line, 'Selected', 'off');
                        continue
                    case ''
                        % Skip this line, continue with the rest
                        set_param(line, 'Selected', 'off');
                        continue
                end
            % 3) Check for scoped goto (current level and above) conflicts
            elseif ~isempty(conflictsScopedGotos)
                answer = questdlg(['A scoped goto named "' signalName '" already exists.' ...
                    char(10) ' Proceed with transformation?'], ...
                    'Line to Goto/Froms: Warning', ...
                    'Yes', 'Change Name', 'No', 'Change Name');
                switch answer
                    case 'Yes'
                        % Use the provided tag
                    case 'Change Name'
                        % Try again
                        signalName = gotoGUI;
                    case 'No'
                        % Skip this line, continue with the rest
                        set_param(line, 'Selected', 'off');
                        continue
                    case ''
                        % Skip this line, continue with the rest
                        set_param(line, 'Selected', 'off');
                        continue
                end
            end
        end
        if ~isempty(signalName) % Ensure name was provided in the case "Change Name" was selected
            line2Goto(get_param(line, 'Parent'), line, signalName);   % Convert
        else    % Dialog was closed, so skip
            set_param(line, 'Selected', 'off');
            continue;
        end
	end
end