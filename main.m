tic % Begin measuring time of execution

clear variables

numEpochs = 400; % NOTE: Changed generations to epochs because political correctness
numRuns = 20; %Note: D runs slow, so fewer runs is a better idea.
% useD = 0; % 1 - use difference reward, 0 - use global reward
Qinit= 100;

modes = {'const', 'decay', 'softmax', 'softmaxDecay'};
params = [0.1, 0.5, 100, 100];
% [epsilon, starting epsilon, temp, starting temp ]
%
%good values of t


% USE THIS TO SELECT WHICH SELECTION POLICY YOU WANT
% Adjust params as necessary, see below for description of each
% myMode = 4;

penalty=100;  %temp. This penalty should ideally be increased over time to enforce feasiblity

% Values for components below are arbitrary. Change as necessary.
% See create_agents.m for details

% BATTERY
batteryAgents = [6, 6, 4];
% MOTOR
motorAgents = [24];
% PROPELLER
propAgents = [7, 12, 10, 10, 15, 15];
% ROD
rodAgents=[4, 16,11,8];

alpha = 0.1; % Learning rate

[batteryData, motorData, propData, foilData, rodData, matData] = load_data('batterytable.csv', ...
    'motortable.csv', 'propranges.csv', 'airfoiltable.csv','rodtable.csv','materialtable.csv');

data.batteryData = batteryData; data.motorData = motorData;
data.propData = propData; data.foilData = foilData; data.rodData = rodData;
data.matData = matData;

for myMode = 4
    for useD = 1
        run_experiment;
    end
end

% WARNING!!!!!!!!!!!!
% After doing the experiments, ALL the figures will come spewing forth
% (maybe)

toc % Spit out execution time

% comment
