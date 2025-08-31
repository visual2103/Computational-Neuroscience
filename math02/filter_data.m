load('Dots_30_001_all_channels.mat'); % all_data_mat: [mostre x canale]
fs = 1024; % rata de esantionare

[N, numCh] = size(all_data_mat);

% filtrele
[b1,a1] = butter(3, [1 100]/(fs/2), 'bandpass');
[b2,a2] = butter(4, [49.5 50.5]/(fs/2), 'stop');

%filtrare pt fiecare canal
all_data_filt = zeros(size(all_data_mat));

for ch = 1:numCh
    x = all_data_mat(:,ch);
    x = filtfilt(b1, a1, x);
    x = filtfilt(b2, a2, x); % filtrare zero-phase -> evitam intarzierile de faza 
    all_data_filt(:,ch) = x;
end

save('Dots_30_001_all_channels_filtered.mat', 'all_data_filt', '-v7.3');
disp('Filtrarea BUTTERWORTH  , DONE !');

