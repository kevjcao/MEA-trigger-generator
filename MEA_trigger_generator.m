% requires NIDAQmx base at minimum

%% Parameters
% timing logic for triggers (in sec)
% loads default stim protocol if GUI section is disabled
timing.t1 = 0.5;    % deadtime before Trig1
timing.t2 = 3;      % length of each trial, should be = window time in MC Rack
timing.t3 = 0.5;    % time from t1 to stim, must be < t2
timing.t4 = 0.01;   % stim duration
timing.t5 = 20;     % length of delay between trials

counter = 0;
epoch = 5;          % number of trials ("epochs")

%% GUI
satisfied = false;

while satisfied == false
    choice = menu('Build a new protocol or load one?', 'Build', 'Load');
    if choice == 1      % add prompt and inputdlg window
        deadtime = input('Please enter your deadtime: ');
        window = input('How long would you like to record for (symmetrical around stimulus)?: ');
        stimlength = input('How long would you like to stimulate for?:  ');
        trialtime = input('How long between each trial?: ');
        fs = 1000;
        t = 0-(window/2 + 0.01 + deadtime):1/fs:trialtime - (window/2 + 0.01 + deadtime);

        figure
        trig1 = rectpuls(t-deadtime, 0.01);
        ax1 = subplot(3,1,1);
        plot(t,trig1,'k')
        axis off
        title('Start new file (Trigger 1)')
        text(-3.5, 0.5, sprintf('Deadtime = \n %0.001f s', round(deadtime,3)));
        
        trig2 = rectpuls(t-(deadtime+0.01+window/2),window);
        ax2 = subplot(3,1,2);
        set(gca,'visible','off')
        plot(t,trig2,'k')
        axis off 
        title('Write data to file (Trigger 2)')
        text(window + deadtime+0.1, 0.5, sprintf('Window length = \n %0.001f s', window));
        
        trig3 = rectpuls(t-(deadtime+0.01+window/2), stimlength);
        ax3 = subplot(3,1,3);
        plot(t, trig3, 'k')
        axis off
        title('Stimulate with LED (Trigger 3)')
        text(-2, 0.5, sprintf('Time to \n stim = \n %0.001f s', deadtime + window/2));
        text(window/2+1, 0.8, sprintf('Stimulus length = \n %1.0f ms', stimlength*1e3));
        text(trialtime/2, -0.1, sprintf('Total trial time = %1.0f s', trialtime));
        
        linkaxes([ax1, ax2, ax3], 'x')

        timing.t1 = deadtime;
        timing.t2 = window;
        timing.t3 = window/2;
        timing.t4 = stimlength;
        timing.t5 = trialtime - (deadtime+0.01+window);

        saveq = menu('Do you want to save your new stimulus protocol?','Yes','No');
        if saveq == 1
            uisave('timing', 'timing.mat');
            if menu('Are you satisfied with your stimulus design?', 'Yes', 'No') == 1
                satisfied = true;
            end
        end
        
        if saveq == 2
            if menu('Are you satisfied with your stimulus design?', 'Yes', 'No') == 1
                satisfied = true;   
            end
        end
        
    end
    
    if choice == 2
        uiload;
        deadtime = timing.t1;
        window = timing.t2;
        stimlength = timing.t4;
        trialtime = timing.t5 + deadtime + 0.01 + window;
        fs = 1000;
        t = 0-(window/2 + 0.01 + deadtime):1/fs:trialtime - (window/2 + 0.01 + deadtime);

        figure
        trig1 = rectpuls(t-deadtime, 0.01);
        ax1 = subplot(3,1,1);
        plot(t,trig1,'k')
        axis off
        title('Start new file (Trigger 1)')
        text(-3.5, 0.5, sprintf('Deadtime before new file = \n %0.001f s', round(deadtime,3)));

        trig2 = rectpuls(t-(deadtime+0.01+window/2),window);
        ax2 = subplot(3,1,2);
        set(gca,'visible','off')
        plot(t,trig2,'k')
        axis off 
        title('Write data to file (Trigger 2)')
        text(window + deadtime+0.1, 0.5, sprintf('Window length = \n %0.001f s', window));
        
        trig3 = rectpuls(t-(deadtime+0.01+window/2),stimlength);
        ax3 = subplot(3,1,3);
        plot(t, trig3, 'k')
        axis off
        title('Stimulate with LED (Trigger 3)')
        text(-2, 0.5, sprintf('Time to \n stim = \n %0.001f s', deadtime + window/2));
        text(window/2+1, 0.8, sprintf('Stimulus length = \n %1.0f ms', stimlength*1e3));
        text(trialtime/2, -0.1, sprintf('Total trial time = %1.0f s', trialtime));
        
        linkaxes([ax1, ax2, ax3], 'x')
        
        if menu('Are you satisfied with your stimulus design?', 'Yes', 'No') == 1
            satisfied = true;
        end
    end
end

%% DAQ setup
% check BOB pinning - hardcode digital outs

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
    outputSingleScan(nidaq, [0 0 0]);
    pause(timing.t5);                   % wait time between trials

    counter = counter + 1;
    fprintf('Trial %d \n', counter);
    toc
end


