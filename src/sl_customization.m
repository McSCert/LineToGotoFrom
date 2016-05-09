%% Register custom menu function to beginning of Simulink Editor's context menu
function sl_customization(cm)
	cm.addCustomMenuFcn('Simulink:PreContextMenu', @getMcMasterTool);
end

%% Define custom menu function
function schemaFcns = getMcMasterTool(callbackInfo) 
    if (strcmp(get_param(gcb, 'BlockType'), 'Goto') || ...
        strcmp(get_param(gcb, 'BlockType'), 'From')) && ...
        strcmp(get_param(gcb, 'Selected'), 'on')
        schemaFcns = {@Goto2LineSchema};
    elseif ~isempty(gcls)
        schemaFcns = {@Line2GotoSchema};
    else
        schemaFcns = {};
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
	% While there are lines selected
    % Note: Loop will terminate because at each iteration lines are deleted
	while ~isempty(gcls)
        % Get the lines
        lines = gcls;
        
        % Get first one of the list
        l = lines(1);
        signalName = get_param(l, 'Name'); 
        
        % If the signal line has no name
        if isempty(signalName) || ~isvarname(signalName)
            signalName = gotoGUI;    % Ask user for a name
        end
        
        if isempty(signalName)   % Dialog was closed, so stop transformation
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
                    'Yes', 'Change Name', 'No', 'No');
                switch answer 
                    case 'Yes'
                        disp(['Warning: Goto block named "', signalName, '" already exists locally:'])
                        disp(conflictLocalGotos)
                    case 'Change Name'
                        % Try again
                        signalName = gotoGUI;
                    case 'No'
                        % Skip this line, continue with the rest
                        set_param(l, 'Selected', 'off');
                        continue
                end 
            % 2) Check for global goto (anywhere in the model) conflicts 
            elseif ~isempty(conflictsGlobalGotos)
                answer = questdlg(['A global goto named "' signalName '" already exists.' ...
                    char(10) ' Proceed with transformation?'], ...
                    'Line to Goto/Froms: Warning', ...
                    'Yes', 'Change Name', 'No', 'No');
                switch answer 
                    case 'Yes'
                        disp(['Warning: Goto block named "' signalName '" overlaps with existing global goto:'])
                        disp(conflictsGlobalGotos)
                    case 'Change Name'
                        % Try again
                        signalName = gotoGUI;
                    case 'No'
                        % Skip this line, continue with the rest
                        set_param(l, 'Selected', 'off');
                        continue
                end
            % 3) Check for scoped goto (current level and above) conflicts
            elseif ~isempty(conflictsScopedGotos)
                answer = questdlg(['A scoped goto named "' signalName '" already exists.' ...
                    char(10) ' Proceed with transformation?'], ...
                    'Line to Goto/Froms: Warning', ...
                    'Yes', 'Change Name', 'No', 'No');
                switch answer 
                    case 'Yes'
                        disp(['Warning: Goto block named "' signalName '" overlaps with existing scoped goto(s):'])
                        disp(conflictsScopedGotos)
                    case 'Change Name'
                        % Try again
                        signalName = gotoGUI;
                    case 'No'
                        % Skip this line, continue with the rest
                        set_param(l, 'Selected', 'off');
                        continue 
                end
            end              
        end
        if ~isempty(signalName) % Ensure name was provided in the case "Change Name" was selected
            line2Goto(gcs, lines(1), signalName);   % Convert
        else    % Dialog was closed, so skip
            set_param(l, 'Selected', 'off');
            continue;
        end
	end
end