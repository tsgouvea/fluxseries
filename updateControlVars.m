function updateControlVars()
%% Define variables
global BpodSystem
global TaskParameters
global Latent
ABC = 'ABC';

%% Compute visited states
listStates = BpodSystem.Data.RawData.OriginalStateNamesByNumber{end};
visited = BpodSystem.Data.RawData.OriginalStateData(end); visited = visited{:};
if numel(visited) == 1
    return
end

%% Compute visitations matrix
ndxRwdArm = listStates{visited(end)}(end)==ABC;

I = eye(3);
Latent.Visits(find(ndxRwdArm),:) = I(find(ndxRwdArm),:);
Latent.Visits(find(~ndxRwdArm),find(ndxRwdArm)) = 1;

%% Set State1 for next trial

if TaskParameters.GUI.Deplete
    Latent.State1 = ['IRI_' ABC(ndxRwdArm) '_' listStates{visited(end-1)}(end-2:end)];
    Latent.State1(end-3+find(all(Latent.Visits,2))) = '1';
    try
        Latent.State1(end-3+find(ndxRwdArm)) = Latent.ListX(find(Latent.ListX==Latent.State1(end-3+find(ndxRwdArm)))+1);
    catch
        warning('Animal collected a sequence of rewards longer than allowed. Try increasing Latent.ListX, and consider checking noseports. (TG Feb 2, 2018)')
    end
    for iPatch = find(~ndxRwdArm)
        if ~strcmp(Latent.State1(end-3+iPatch),'1')
            Latent.State1(end-3+iPatch) = '0'; % with exception of last visited arm, all others must be set to either 0 or 1
        end
    end
else
    Latent.State1 = ['setup' listStates{visited(end-1)}(end-2:end)];
    Latent.State1(end-3+find(all(Latent.Visits,2))) = '1';
    Latent.State1(end-3+find(ndxRwdArm)) = '0';
end

%% Set reward magnitudes for next trial
for iPatch = 1:numel(ABC)
    Latent.(['rew' ABC(iPatch)]) = TaskParameters.GUI.rewFirst;
    TaskParameters.GUI.(['rew' ABC(iPatch)]) = Latent.(['rew' ABC(iPatch)]);
    BpodSystem.Data.Custom.(['rew' ABC(iPatch)])(BpodSystem.Data.nTrials) = Latent.(['rew' ABC(iPatch)]);
end

if TaskParameters.GUI.Deplete
    if (strncmp('water',listStates{visited(end)},5))
        n = find(Latent.ListX==Latent.State1(end-3+find(ndxRwdArm)))-1;
        Latent.(['rew' ABC(ndxRwdArm)]) = ceil(TaskParameters.GUI.rewFirst*... % initial magnitude times...
            (TaskParameters.GUI.rewLast/TaskParameters.GUI.rewFirst)^((n-1)/(TaskParameters.GUI.(['rewN_' ABC(ndxRwdArm)])-1))*... % deplete factor times...
            ((1-TaskParameters.GUI.DepleteVar)+TaskParameters.GUI.DepleteVar*rand*2)); % bounded unif noise
        TaskParameters.GUI.(['rew' ABC(ndxRwdArm)]) = Latent.(['rew' ABC(ndxRwdArm)]);
        BpodSystem.Data.Custom.(['rew' ABC(ndxRwdArm)])(BpodSystem.Data.nTrials) = Latent.(['rew' ABC(ndxRwdArm)]);
    end
end

end