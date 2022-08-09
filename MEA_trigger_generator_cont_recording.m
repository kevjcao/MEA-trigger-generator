% requires NIDAQmx base 

%% parameters
% timing logic for triggers (in sec)
timing.t1 = 1;      % stim duration, in sec
timing.t2 = 20;     % length of delay (in sec) between epochs / trials

numstim = 3;        % number of stimuli 

%% DAQ setup
% check BOB pinning - hardcode digital outs

nidaq = daq.createSession('ni');    % create NI DAQ
addDigitialChannel(nidaq, 'Dev1', 'Port1/Line3', 'OutputOnly'); % Trig1 - create new file in MC rack
addDigitialChannel(nidaq, 'Dev1', 'Port1/Line0', 'OutputOnly'); % Trig2 - set window and write data to new file
addDigitialChannel(nidaq, 'Dev1', 'Port1/Line7', 'OutputOnly'); % Trig3 - send TTL to LED stim
pause on;

%% periods

for k = 1:numstim
    outputSingleScan(nidaq, [0 0 1]);
    pause(timing.t1);                   % stim period via Trig 3 TTL
    outputSingleScan(nidaq, [0 0 0]);
    pause(timing.t2);                   % wait time
end
