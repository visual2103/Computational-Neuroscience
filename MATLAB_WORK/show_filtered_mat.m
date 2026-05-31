function vizualizeaza_filtrare(all_data, all_data_filt, fs, canal)
% Vizualizare comparativă semnal EEG original vs filtrat (Butterworth)
% all_data      - matrice originală [mostre x canale]
% all_data_filt - matrice filtrată  [mostre x canale]
% fs            - rata de esantionare (ex: 1024)
% canal         - index canal pentru vizualizare (default 1)

if nargin < 4
    canal = 1;
end

x_orig = all_data(:,canal);
x_filt = all_data_filt(:,canal);
N = length(x_orig);
t = (0:N-1)/fs;

figure('Name', ['Comparatie filtrare EEG - canal ' num2str(canal)], 'Position', [100 100 1200 700]);

subplot(2,2,1)
plot(t, x_orig);
title('Original (nefiltrat)');
xlabel('Timp [s]'); ylabel('Amplitudine [uV]');
xlim([0 min(5, t(end))])

subplot(2,2,2)
plot(t, x_filt);
title('Filtrat (Butterworth 1-100Hz, notch 50Hz)');
xlabel('Timp [s]'); ylabel('Amplitudine [uV]');
xlim([0 min(5, t(end))])

% FFT
f = (0:N-1)*(fs/N);
X_orig = abs(fft(x_orig));
X_filt = abs(fft(x_filt));

subplot(2,2,3)
plot(f, X_orig);
title('Spectru original');
xlabel('Frecvență [Hz]'); ylabel('Amplitudine');
xlim([0 150])

subplot(2,2,4)
plot(f, X_filt);
title('Spectru filtrat');
xlabel('Frecvență [Hz]'); ylabel('Amplitudine');
xlim([0 150])

sgtitle(['Vizualizare filtrare EEG - Canal ' num2str(canal)])
end



load('Dots_30_001_all_channels.mat');          % matricea originală
load('Dots_30_001_all_channels_filtered.mat'); % matricea filtrată

fs = 1024;  % rata de eșantionare (modifică dacă e cazul)

vizualizeaza_filtrare(all_data_mat, all_data_filt, fs, 1); % vezi canalul 1
