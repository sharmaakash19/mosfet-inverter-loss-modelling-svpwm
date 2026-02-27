% THREE-PHASE INVERTER – SPACE VECTOR PWM

clc; clear; close all;

%% USER PARAMETERS
Fs   = 10e3;          % Switching frequency [Hz]
fref = 50;            % Fundamental frequency [Hz]
Vdc  = 60;           % DC voltage [V]
m    = 0.8;           % Modulation index 

% Reference voltage magnitude (SVPWM)
Mag  = m * Vdc / sqrt(3);

%% TIME SETTINGS
Tfund = 1 / fref;     % Fundamental period = 20 ms
Fsamp = 20 * Fs;      % Sampling frequency
dt    = 1 / Fsamp;    % Time step
t     = 0:dt:Tfund*5;   % 5 sine cycle
Nt    = length(t);

Pulse = zeros(Nt,6);  % [S1 S2 S3 S4 S5 S6]

%% SVM LOOP
for k = 1:Nt
    clk = t(k);

    % Electrical angle (0–2pi)
    ang = mod(2*pi*fref*clk, 2*pi);

    % Sector number (1–6)
    Sec = floor(ang / (pi/3)) + 1;
    if Sec > 6
        Sec = 6;
    end

    % Compute gate signals
    Pulse(k,:) = svm_compute(Fs, Mag, ang, Sec, Vdc, clk);
end


% SVM FUNCTION

function gates = svm_compute(Fs, Mag, ang, Sec, Vdc, clk)

Ts = 1 / Fs;

% Angle inside sector (0–60 deg)
alpha = mod(ang - (Sec-1)*pi/3, pi/3);

% Switching times
T1 = Mag * sqrt(3)/Vdc * sin(pi/3 - alpha) * Ts;
T2 = Mag * sqrt(3)/Vdc * sin(alpha) * Ts;
T0 = (Ts - T1 - T2)/2;

% Time within PWM period
t_pwm = mod(clk, Ts);

% SVM timing sequence:
% T0/4 – T1/2 – T2/2 – T0/2 – T2/2 – T1/2 – T0/4
b1 = T0/4;
b2 = b1 + T1/2;
b3 = b2 + T2/2;
b4 = b3 + T0/2;
b5 = b4 + T2/2;
b6 = b5 + T1/2;

if      t_pwm < b1, interval = 1;
elseif  t_pwm < b2, interval = 2;
elseif  t_pwm < b3, interval = 3;
elseif  t_pwm < b4, interval = 4;
elseif  t_pwm < b5, interval = 5;
elseif  t_pwm < b6, interval = 6;
else    interval = 7;
end

% Switching states (upper devices)
switch Sec
    case 1, sw = [0 1 1 1 1 1 0; 0 0 1 1 1 0 0; 0 0 0 1 0 0 0];
    case 2, sw = [0 0 1 1 1 0 0; 0 1 1 1 1 1 0; 0 0 0 1 0 0 0];
    case 3, sw = [0 0 0 1 0 0 0; 0 1 1 1 1 1 0; 0 0 1 1 1 0 0];
    case 4, sw = [0 0 0 1 0 0 0; 0 0 1 1 1 0 0; 0 1 1 1 1 1 0];
    case 5, sw = [0 0 1 1 1 0 0; 0 0 0 1 0 0 0; 0 1 1 1 1 1 0];
    case 6, sw = [0 1 1 1 1 1 0; 0 0 0 1 0 0 0; 0 0 1 1 1 0 0];
end

% Upper switches
S1 = sw(1,interval);
S3 = sw(2,interval);
S5 = sw(3,interval);

% Lower switches (complementary, no dead-time)
S2 = 1 - S1;
S4 = 1 - S3;
S6 = 1 - S5;

gates = [S1 S2 S3 S4 S5 S6];
end

%% PLOTS
labels = {'Upper A','Lower A','Upper B','Lower B','Upper C','Lower C'};
figure('Name','SVM Gate Signals');
for i = 1:6
    subplot(3,2,i)
    stairs(t, Pulse(:,i),'LineWidth',1.2)
    ylim([-0.2 1.2]); grid on;
    title(labels{i})
    xlabel('Time [s]')
end

%%  LTspice
Vgate = 1;                 % Gate voltage level [V]
GateV = Pulse * Vgate;      

names = {'S1','S2','S3','S4','S5','S6'};

for i = 1:6
    fname = sprintf('gate_%s.txt', names{i});
    fid = fopen(fname,'w');
    for k = 1:Nt
        fprintf(fid,'%.9e %.3f\n', t(k), GateV(k,i));
    end
    fclose(fid);
    fprintf('Exported %s\n', fname);
end
