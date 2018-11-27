function varargout = panel_export_bids(varargin)
% PANEL_BIDS_METADATA: Additional metadata for BIDS export.
% 
% USAGE:  bstPanelNew = panel_export_bids('CreatePanel')
%                   s = panel_export_bids('GetPanelContents')

% @=============================================================================
% This function is part of the Brainstorm software:
% https://neuroimage.usc.edu/brainstorm
% 
% Copyright (c)2000-2018 University of Southern California & McGill University
% This software is distributed under the terms of the GNU General Public License
% as published by the Free Software Foundation. Further details on the GPLv3
% license can be found at http://www.gnu.org/copyleft/gpl.html.
% 
% FOR RESEARCH PURPOSES ONLY. THE SOFTWARE IS PROVIDED "AS IS," AND THE
% UNIVERSITY OF SOUTHERN CALIFORNIA AND ITS COLLABORATORS DO NOT MAKE ANY
% WARRANTY, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO WARRANTIES OF
% MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE, NOR DO THEY ASSUME ANY
% LIABILITY OR RESPONSIBILITY FOR THE USE OF THIS SOFTWARE.
%
% For more information type "brainstorm license" at command prompt.
% =============================================================================@
%
% Authors: Martin Cousineau, 2018

eval(macro_method);
end


%% ===== CREATE PANEL =====
function [bstPanelNew, panelName] = CreatePanel(sProcess, sFiles)  %#ok<DEFNU>  
    panelName = 'ExportBidsOptions';
    % Java initializations
    import java.awt.*;
    import javax.swing.*;
    % No input
    if isempty(sFiles) || strcmpi(sFiles(1).FileType, 'import')
        bstPanelNew = [];
        panelName = [];
        return;
    end

    % Create main main panel
    jPanelMain = java_create('javax.swing.JPanel');
    jPanelMain.setLayout(java_create('java.awt.GridBagLayout'));
    c = GridBagConstraints();
    c.fill = GridBagConstraints.BOTH;
    c.gridx = 1;
    c.weightx = 1;
    c.weighty = 1;
    c.insets = Insets(3,5,3,5);
    
    % ===== PANEL CONTENT =====
    jPanelProj = gui_component('Panel');
    jPanelProj.setLayout(BoxLayout(jPanelProj, BoxLayout.Y_AXIS));
    jPanelProj.setBorder(BorderFactory.createCompoundBorder(java_scaled('titledborder', 'Project description'), BorderFactory.createEmptyBorder(0,5,0,0)));
    jPanelOpt = gui_river([2,2], [2,4,2,4]);
    gui_component('Label', jPanelOpt, '', 'Project Name: ');
    jTextProjName = gui_component('Text', jPanelOpt, 'hfill', '');
    jPanelProj.add(jPanelOpt);
    jPanelOpt = gui_river([2,2], [2,4,2,4]);
    gui_component('Label', jPanelOpt, 'br', 'Project ID: ');
    jTextProjID = gui_component('Text', jPanelOpt, 'hfill', '');
    jPanelProj.add(jPanelOpt);
    jPanelOpt = gui_river([2,2], [2,4,2,4]);
    gui_component('label', jPanelOpt, 'br', 'Project Description: ');
    jTextProjDesc = gui_component('textfreq', jPanelOpt, 'br hfill', '');
    jTextProjDesc.setColumns(java_scaled('value', 30));
    jPanelProj.add(jPanelOpt);
    jPanelOpt = gui_river([2,2], [2,4,2,4]);
    gui_component('label', jPanelOpt, 'br', 'Participant Groups: ');
    jTextGroups = gui_component('textfreq', jPanelOpt, 'br hfill', '');
    jPanelProj.add(jPanelOpt);
    c.gridy = 1;
    jPanelMain.add(jPanelProj, c);
    
    jPanelJson = gui_component('Panel');
    jPanelJson.setLayout(BoxLayout(jPanelJson, BoxLayout.Y_AXIS));
    jPanelJson.setBorder(BorderFactory.createCompoundBorder(java_scaled('titledborder', 'Additional metadata'), BorderFactory.createEmptyBorder(0,5,0,0)));
    jPanelOpt = gui_river([2,2], [2,4,2,4]);
    gui_component('label', jPanelOpt, 'br', 'Additional dataset description JSON fields: ');
    jTextJsonDataset = gui_component('textfreq', jPanelOpt, 'br hfill', '');
    jPanelJson.add(jPanelOpt);
    jPanelOpt = gui_river([2,2], [2,4,2,4]);
    gui_component('label', jPanelOpt, 'br', 'Additional MEG sidecar JSON fields: ');
    jTextJsonMeg = gui_component('textfreq', jPanelOpt, 'br hfill', '');
    jPanelJson.add(jPanelOpt);
    c.gridy = 2;
    jPanelMain.add(jPanelJson, c);
    
    % ===== VALIDATION BUTTON =====
    jPanelOk = gui_river();
    gui_component('Button', jPanelOk, 'br right', 'OK', [], [], @ButtonOk_Callback);
    c.gridy = 3;
    jPanelMain.add(jPanelOk, c);

    % ===== PANEL CREATION =====
    % Put everything in a big scroll panel
    jPanelScroll = javax.swing.JScrollPane(jPanelMain);
    %jPanelScroll.add(jPanelMain);
    %jPanelScroll.setPreferredSize(jPanelMain.getPreferredSize());
    % Return a mutex to wait for panel close
    bst_mutex('create', panelName);
    % Controls list
    ctrl = struct('jTextComment',     jTextProjName, ...
                  'jTextProjID',      jTextProjID, ...
                  'jTextProjDesc',    jTextProjDesc, ...
                  'jTextGroups',      jTextGroups, ...
                  'jTextJsonDataset', jTextJsonDataset, ...
                  'jTextJsonMeg',     jTextJsonMeg);
    % Create the BstPanel object that is returned by the function
    bstPanelNew = BstPanel(panelName, jPanelScroll, ctrl);
    
    UpdatePanel();
    
    
%% =================================================================================
%  === INTERNAL CALLBACKS ==========================================================
%  =================================================================================
%% ===== OK BUTTON =====
    function ButtonOk_Callback(varargin)
        % Validate JSON
        jsonDataset = char(jTextJsonDataset.getText());
        jsonMeg = char(jTextJsonMeg.getText());
        if ~ValidateJson(jsonDataset)
            jsonError = 'dataset description';
        elseif ~ValidateJson(jsonMeg)
            jsonError = 'MEG sidecar files';
        else
            jsonError = [];
        end
        if ~isempty(jsonError)
            java_dialog('error', ['The JSON you entered for the ', jsonError, ' is invalid.', ...
                10, 'Please check your syntax and try again.'], 'Invalid JSON', jPanelMain);
            return;
        end
        
        % Save new options
        ExportBidsOptions = bst_get('ExportBidsOptions');
        ExportBidsOptions.ProjName = char(jTextProjName.getText());
        ExportBidsOptions.ProjID = char(jTextProjID.getText());
        ExportBidsOptions.ProjDesc = char(jTextProjDesc.getText());
        ExportBidsOptions.Groups = char(jTextGroups.getText());
        ExportBidsOptions.JsonDataset = jsonDataset;
        ExportBidsOptions.JsonMeg = jsonMeg;
        bst_set('ExportBidsOptions', ExportBidsOptions);
        
        % Release mutex and keep the panel opened
        bst_mutex('release', panelName);
    end

%% ===== UPDATE PANEL =====
    function UpdatePanel(varargin)
        ExportBidsOptions = bst_get('ExportBidsOptions');
        jTextProjName.setText(ExportBidsOptions.ProjName);
        jTextProjID.setText(ExportBidsOptions.ProjID);
        jTextProjDesc.setText(ExportBidsOptions.ProjDesc);
        jTextGroups.setText(ExportBidsOptions.Groups);
        jTextJsonDataset.setText(ExportBidsOptions.JsonDataset);
        jTextJsonMeg.setText(ExportBidsOptions.JsonMeg);
    end

end

function isValid = ValidateJson(jsonText)
    if isempty(jsonText)
        isValid = 1;
        return;
    else
        try
            bst_jsondecode(jsonText);
            isValid = 1;
        catch
            isValid = 0;
        end
    end
end
