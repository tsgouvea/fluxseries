function [ sma ] = FluxStateMaker( sma )
%FLUXSTATEMAKER Defines states listed but yet undefined in SMA

if all(logical(sma.StatesDefined))
    return
end

stateName = sma.StateNames{find(~logical(sma.StatesDefined),1)};

try
    assert(strncmp(stateName,'IRI',3) | strncmp(stateName,'setup',5) | strncmp(stateName,'water',5))
catch
    error('Don''t know how to handle state with this name (TG, Feb1 18)')
end

%%
global Latent
global TaskParameters
smaTimer = 0;
smaChange = {};
smaOut = {};
ABC = 'ABC';
Ports_ABC = num2str(TaskParameters.GUI.Ports_ABC);

if strncmp(stateName,'setup',5)
    for iPatch = 1:3
        if strcmp(stateName(5+iPatch),'0')
            for jPatch = find(1:3~=iPatch)
                if find(Latent.ListX == stateName(end-3+jPatch)) > find(Latent.ListX == '1')
                    PortIn = ['Port' Ports_ABC(iPatch) 'In'];
                    nextState = stateName; nextState(1:5) = 'setup'; nextState(5+jPatch) = '0';                    
                    smaChange = {smaChange{:}, PortIn, nextState};
                end
            end
        elseif find(Latent.ListX == stateName(end-3+iPatch)) > find(Latent.ListX == '0')            
            PortIn = ['Port' num2str(floor(mod(TaskParameters.GUI.Ports_ABC/10^(3-iPatch),10))) 'In'];
            nextState = ['water_' ABC(iPatch)];
            smaChange = {smaChange{:}, PortIn, nextState};
            if stateName(end-3+iPatch) == '1' && TaskParameters.GUI.Cued
                smaOut = {smaOut{:}, strcat('PWM',Ports_ABC(iPatch)),255, 'WireState',2^(iPatch-1)};
            end
        end
    end
elseif strncmp(stateName,'water',5)
    Port = floor(mod(TaskParameters.GUI.Ports_ABC/10^(3-find(ABC==stateName(end))),10));
    ValveTime = GetValveTimes(Latent.(['rew' stateName(end)]), Port);
    smaTimer = ValveTime;
    smaChange = {'Tup','exit'};
    smaOut = {smaOut{:}, 'ValveState', 2^(Port-1)};
    if TaskParameters.GUI.Cued
        smaOut = {smaOut{:},strcat('PWM',Ports_ABC(ABC==stateName(end))),0, 'WireState',0};
    end
elseif strncmp(stateName,'IRI',3)
    for iPatch = 1:numel(ABC)
        if strcmp(stateName(5),ABC(iPatch)) % PATCH WHERE LAST REWARD WAS OBTAINED
            smaChange = {smaChange{:}, 'GlobalTimer4_End',['setup' stateName(end-2:end)]}; % THIS WILL BREAK IF ANIMAL COLLECTS >numel(ListX) REWARDS ON SAME SIDE
            if TaskParameters.GUI.Cued
                smaOut = {smaOut{:}, strcat('PWM',Ports_ABC(iPatch)),0, 'WireState',0};
            end
        else % ALL OTHER PATCHES
            if strcmp(stateName(end-3+iPatch),'0')
                for jPatch = find(1:3~=iPatch)
                    if find(Latent.ListX == stateName(end-3+jPatch)) > find(Latent.ListX == '1')
                        assert(find(ABC==stateName(5))==jPatch)
                        PortIn = ['Port' Ports_ABC(iPatch) 'In'];
                        nextState = ['setup' stateName(end-2:end)]; nextState(end-3+jPatch) = '0';
                        smaChange = {smaChange{:}, PortIn, nextState};
                    end
                end
            elseif strcmp(stateName(end-3+iPatch),'1')
                smaChange = {smaChange{:},['Port' num2str(floor(mod(TaskParameters.GUI.Ports_ABC/10^(3-iPatch),10))) 'In'],['water_' ABC(iPatch)]};
                if TaskParameters.GUI.Cued
                    smaOut = {smaOut{:}, strcat('PWM',Ports_ABC(iPatch)),255,'WireState',2^(iPatch-1)};
                end
            end
        end
    end
    smaOut = {smaOut{:}, 'GlobalTimerTrig', 4};
elseif strcmp(stateName,'exit')
    return
end

%%
sma = AddState(sma, 'Name', stateName,...
    'Timer', smaTimer,...
    'StateChangeConditions', smaChange,...
    'OutputActions', smaOut);