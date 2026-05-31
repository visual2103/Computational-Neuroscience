load('Dots_30_001_all_channels_filtered.mat'); 
fs = 1024; % rata de esantionare
% filtre suplimentare

[b_hp, a_hp] = butter(3, 1 / (fs / 2), 'high'); % high-pass 1 Hz -> pt drift , variatii lente din cauza electrozilor/muschi 
[b_lp, a_lp] = butter(3, 150 / (fs / 2), 'low'); % low-pass 150 Hz -> zgomot electric / artefacte musculare
[b_notch50, a_notch50] = butter(4, [49 51] / (fs / 2), 'stop'); % Notch 50 Hz -> zgomot retea
[b_notch100, a_notch100] = butter(4, [99 101] / (fs / 2), 'stop'); % Notch 100  ->armonica 

[N,numCh] = size(all_data_filt); 
all_data_filt2 = zeros(size(all_data_filt));

for i = 1:numCh
    % am folosit filtfilt pt a evita intarzierile de faza deoarece aplica filtrarea inainte si inapoi => zero-phase
    all_data_filt2(:,i) = filtfilt(b_hp, a_hp, all_data_filt(:,i)); 
    all_data_filt2(:,i) = filtfilt(b_lp, a_lp, all_data_filt2(:,i)); 
    all_data_filt2(:,i) = filtfilt(b_notch50, a_notch50, all_data_filt2(:,i)); 
    all_data_filt2(:,i) = filtfilt(b_notch100, a_notch100, all_data_filt2(:,i)); 
end

save('Dots_30_001_all_channels_filtered_v2.mat', 'all_data_filt2','-v7.3');
disp('Filtrarea suplimentara , DONE !');

% Selectăm un canal pentru analiză (de exemplu, canalul 1)
ch = 1;

% Semnalul original (înainte de filtrare suplimentară)
x_original = all_data_filt(:, ch);

% Semnalul filtrat (după filtrare suplimentară)
x_filtered = all_data_filt2(:, ch);

% Calculăm FFT pentru semnalul original
N = length(x_original); % Numărul de mostre
f = (0:N-1) * (fs / N); % Vectorul frecvențelor
X_original = abs(fft(x_original)) / N;

% Calculăm FFT pentru semnalul filtrat
X_filtered = abs(fft(x_filtered)) / N;

% Vizualizăm spectrul
figure;
plot(f(1:N/2), X_original(1:N/2), 'r', 'LineWidth', 1.5); hold on;
plot(f(1:N/2), X_filtered(1:N/2), 'b', 'LineWidth', 1.5);
xlabel('Frecvența (Hz)');
ylabel('Amplitudinea');
legend('Original', 'Filtrat');
title(['Spectrul semnalului pentru canalul ', num2str(ch)]);
grid on;