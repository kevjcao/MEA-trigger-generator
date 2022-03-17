% requires NIDAQmx base at minimum

%% Parameters
% timing logic for triggers (in sec)
timing.t1 = 0.5;    % deadtime before Trig1
timing.t2 = 3;      % length of each trial, should be = window time in MC Rack
timing.t3 = 0.5;    % time from t1 to stim, must be < t2
timing.t4 = 0.01;   % stim duration
timing.t5 = 20;     % length of delay between trials

% convert to datum ?

counter = 0;
epoch = 5;          % number of trials ("epochs")

%% DAQ setup

nidaq = daq.createSession('ni');    % create NI DAQ 
addDigitalChannel(nidaq, 'Dev1', 'Port1/Line3', 'OutputOnly');  % Trig1 - create new file in MC Rack
addDigitalChannel(nidaq, 'Dev1', 'Port1/Line0', 'OutputOnly');  % Trig2 - set window / trial length
addDigitalChannel(nidaq, 'Dev1', 'Port1/Line7', 'OutputOnly');  % Trig3 - LED stim
pause on;

%% DO loop

for k = 1:epoch
    tic
    pause(timing.t1);                   % deadtime before sending Trig1 TTL
    outputSingleScan(nidaq, [1 0 0]);
    pause(0.01);                        % 10 ms Trig1 TTL
    outputSingleScan(nidaq, [0 1 0]);   % Trig2 TTL on as Trig1 TTL off
    pause(timing.t3);
    outputSingleScan(nidaq, [0 1 1]);
    pause(timing.t4);                   % 10 ms Trig3 TTL
    outputSingleScan(nidaq, [0 1 0]);
    pause(timing.t2 - timing.t3);       % remaining time of trial
    outputSingleScan(nidaq, [0 0 0)];
    pause(timing.t5);                   % wait time between trials

    counter = counter + 1;
    fprintf('Trial %d ]n', counter);
    toc
end


