function FluxSeries
% Reproduction on Bpod of protocol used in the PatonLab, MATCHINGvFix

global BpodSystem
global TaskParameters
global Latent
global sessionTimer

%% Task parameters
TaskParameters = BpodSystem.ProtocolSettings;
if isempty(fieldnames(TaskParameters))
    
    %% Reward
    TaskParameters.GUI.rewFirst = 30;
    TaskParameters.GUI.rewLast = 5;
    TaskParameters.GUI.rewN_A = 6;
    TaskParameters.GUI.rewN_B = 12;
    TaskParameters.GUI.rewN_C = 24;
%     TaskParameters.GUI.rewSum = round(sum(TaskParameters.GUI.rewFirst*(TaskParameters.GUI.rewLast/TaskParameters.GUI.rewFirst).^([0:TaskParameters.GUI.rewN-1]/(TaskParameters.GUI.rewN-1))));
%     TaskParameters.GUIMeta.rewSum.Style = 'text';
    TaskParameters.GUI.IRI = 1;
    TaskParameters.GUI.rewA = TaskParameters.GUI.rewFirst;
    TaskParameters.GUIMeta.rewA.Style = 'text';
    TaskParameters.GUI.rewB = TaskParameters.GUI.rewFirst;
    TaskParameters.GUIMeta.rewB.Style = 'text';
    TaskParameters.GUI.rewC = TaskParameters.GUI.rewFirst;
    TaskParameters.GUIMeta.rewC.Style = 'text';
    TaskParameters.GUIPanels.Reward = {'rewFirst','rewLast','rewN_A','rewN_B','rewN_C','IRI','rewA','rewB','rewC'};
    
    %% General
    TaskParameters.GUI.isBridgeUp = false;
    TaskParameters.GUIMeta.isBridgeUp.Style = 'checkbox';
    TaskParameters.GUI.BridgeWhen = 20; % in min
    TaskParameters.GUI.Series = 'ABC';
    TaskParameters.GUIMeta.Series.Style = 'edittext';
    TaskParameters.GUI.Deplete = true; % false: classic concurrent VI; true: rew magnitude decays for repeated responses, resets after different arm visited
    TaskParameters.GUIMeta.Deplete.Style = 'checkbox';
    TaskParameters.GUI.Cued = true; % light on when reward available
    TaskParameters.GUIMeta.Cued.Style = 'checkbox';
    TaskParameters.GUI.Ports_ABC = '123';
    TaskParameters.GUIPanels.General = {'Ports_ABC','Series','Cued','Deplete','isBridgeUp','BridgeWhen'};
    
    %%
    TaskParameters.GUI = orderfields(TaskParameters.GUI);
    
end
BpodParameterGUI('init', TaskParameters);

%% User specific mod
% TaskParameters.GUI.Series = randsample('ABC',3);
% warning('Series ABC shuffled')

%% Trial type vectors

Latent.Visits = eye(3);
Latent.Visits('ABC'==TaskParameters.GUI.Series(1),:) = 1;
Latent.Visits('ABC'==TaskParameters.GUI.Series(2),'ABC'==TaskParameters.GUI.Series(3)) = 1;

Latent.State1 = 'setup000';
Latent.State1(end-3+find(all(Latent.Visits,2))) = '1';

Latent.rewA = TaskParameters.GUI.rewFirst;
Latent.rewB = TaskParameters.GUI.rewFirst;
Latent.rewC = TaskParameters.GUI.rewFirst;
Latent.ListX = native2unicode([48:57,65:90,97:122]);

%% Server data
BpodSystem.Data.Custom.Rig = getenv('computername');
[~,BpodSystem.Data.Custom.Subject] = fileparts(fileparts(fileparts(fileparts(BpodSystem.DataPath))));

BpodSystem.Data.Custom = orderfields(BpodSystem.Data.Custom);

%% Initialize plots
temp = SessionSummary();
for i = fieldnames(temp)'
    BpodSystem.GUIHandles.(i{1}) = temp.(i{1});
end
clear temp
BpodNotebook('init');

%% User Session Start-Script
if true % reshuffles series at beginning of session
    TaskParameters.GUI.Series = randsample(TaskParameters.GUI.Series,numel(TaskParameters.GUI.Series));
    set(BpodSystem.GUIHandles.ParameterGUI.Params{strcmp(BpodSystem.GUIData.ParameterGUI.ParamNames,'Series')}, 'String', TaskParameters.GUI.Series);
    
    Latent.Visits = eye(3);
    Latent.Visits('ABC'==TaskParameters.GUI.Series(1),:) = 1;
    Latent.Visits('ABC'==TaskParameters.GUI.Series(2),'ABC'==TaskParameters.GUI.Series(3)) = 1;
    
    Latent.State1 = 'setup000';
    Latent.State1(end-3+find(all(Latent.Visits,2))) = '1';
end

%% Main loop
getgit()
RunSession = true;
% iTrial = 1;
sessionTimer = tic;

while RunSession
    if  toc(sessionTimer) > TaskParameters.GUI.BridgeWhen*60
        TaskParameters.GUI.isBridgeUp = true ;
        set(BpodSystem.GUIHandles.ParameterGUI.Params{strcmp(BpodSystem.GUIData.ParameterGUI.ParamNames,'isBridgeUp')}, 'Value', TaskParameters.GUI.isBridgeUp);
    end
    TaskParameters = BpodParameterGUI('sync', TaskParameters);
    BpodSystem.ProtocolSettings = TaskParameters;
    
    sma = stateMatrix(TaskParameters.GUI.isBridgeUp);
    SendStateMatrix(sma);
    RawEvents = RunStateMatrix;
    if ~isempty(fieldnames(RawEvents))
        BpodSystem.Data = AddTrialEvents(BpodSystem.Data,RawEvents);
        SaveBpodSessionData;
    end
    
%     timeStamps = BpodSystem.Data.RawData.OriginalStateTimestamps{:};
%     if strcmp(Latent.SetUp(1),'0')
% %         elapsedA = max(timeStamps)-min(timeStamps)
%     end
    
    HandlePauseCondition; % Checks to see if the protocol is paused. If so, waits until user resumes.
    if BpodSystem.BeingUsed == 0
        return
    end
    
    updateControlVars()
%     iTrial = iTrial + 1;
    try
        BpodSystem.GUIHandles = SessionSummary(BpodSystem.Data, BpodSystem.GUIHandles);
    end
end
end