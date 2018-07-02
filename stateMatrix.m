function sma = stateMatrix()
global Latent
global TaskParameters

sma = NewStateMatrix();
sma = SetGlobalTimer(sma,4,TaskParameters.GUI.IRI);
sma = AddState(sma, 'Name', 'state_0',...
    'Timer', 0,...
    'StateChangeConditions', {'Tup', Latent.State1},...
    'OutputActions', {});

while any(~logical(sma.StatesDefined))
    sma = FluxStateMaker(sma);
end
end