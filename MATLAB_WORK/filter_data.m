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
    x = filtfilt(b2, a2, x);
    all_data_filt(:,ch) = x;
end

save('Dots_30_001_all_channels_filtered.mat', 'all_data_filt', '-v7.3');
disp('Filtrarea BUTTERWORTH s-a terminat și s-a salvat fișierul!');

% -----------------------------
% verificare canal 100 
x = all_data_mat(:, 100);        % original orice intre [1,128]
x_filt = all_data_filt(:, 100);  % filtrat

% RMS difference
fprintf('Diferența RMS: %.6f\n', rms(x - x_filt));


N = length(x);
f = (0:N-1)*(fs/N);

X = abs(fft(x));
X_filt = abs(fft(x_filt));

[~, idx_50] = min(abs(f - 50));
fprintf('Frecvența la idx_50: %.3f Hz\n', f(idx_50));

% (49–51 Hz)
idx_band = find(f >= 49.5 & f <= 50.5);
E_orig = sum(X(idx_band));
E_filt = sum(X_filt(idx_band));

fprintf('Energie [49-51Hz], original: %.2f, filtrat: %.2f\n', E_orig, E_filt);

% vizualizare clara
figure;
plot(f, X, 'b'); hold on;
plot(f, X_filt, 'r');
xlim([0 100]);
legend('Original', 'Filtrat');
title('Spectru original vs filtrat, canal 1');
xlabel('Frecvență [Hz]');
ylabel('Amplitudine');
