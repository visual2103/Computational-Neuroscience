% filepath: /Users/alinamacavei/Desktop/NEUROSCIENCE/DataSet/Dots_30_001/auto_reject_bad.m
% Script pentru respingerea automată a canalelor și segmentelor proaste

% Adaugă path-ul către FieldTrip
addpath('/Users/alinamacavei/Desktop/NEUROSCIENCE/fieldtrip-doc/fieldtrip-20250106');
ft_defaults;

fprintf('INCARC SEGMENTELE de la segmentation.m ...\n'); 
load('Dots_30_001_segments.mat');

% Pregătirea datelor în format FieldTrip
data = []; 
data.fsample = fs;

% Etichetarea canalelor
data.label = cell(size(segments,2),1);
for i = 1:size(segments,2)
    data.label{i} = sprintf('chan%03d', i);
end

% Pregătirea structurii pentru trials și time
data.trial = cell(size(segments,3),1); 
data.time = cell(size(segments,3),1);

% Transferul datelor în formatul FieldTrip
for i = 1:size(segments,3)
    data.trial{i} = squeeze(segments(:, :, i))';  % Transpunere (')
    data.time{i} = (0:size(segments,1)-1) / fs;
end

fprintf('Date convertite în format FieldTrip.\n');

% Backup al datelor originale
data_original = data;

%% Pasul 1: Detectarea automată a canalelor proaste

fprintf('\n=== PASUL 1: DETECTAREA AUTOMATĂ A CANALELOR PROASTE ===\n');

% Metoda alternativă: Calculul manual al valorilor aberante
fprintf('Calcularea manuală a canalelor proaste...\n');

% Calcularea valorilor pentru fiecare canal
chan_var = zeros(length(data.label), 1);
chan_max = zeros(length(data.label), 1);
chan_kurtosis = zeros(length(data.label), 1);

% Extragerea datelor pentru analiză
for i = 1:length(data.label)
    chan_data = [];
    for j = 1:length(data.trial)
        chan_data = [chan_data, data.trial{j}(i,:)]; % Concatenează datele de pe toate segmentele
    end
    
    % Calculează metrici
    chan_var(i) = var(chan_data);
    chan_max(i) = max(abs(chan_data));
    
    % Calcularea kurtosis manual
    m = mean(chan_data);
    s = std(chan_data);
    if s > 0
        z = (chan_data - m) / s;
        chan_kurtosis(i) = mean(z.^4) - 3; % Excess kurtosis
    else
        chan_kurtosis(i) = 0;
    end
end

% Identificarea canalelor aberante (outliers)
thresh_z = 3; % Pragul de z-score (ajustează-l dacă este necesar)

% Funcție pentru calculul manual al z-score
calc_zscore = @(x) (x - mean(x)) ./ std(x);

% Z-scores pentru fiecare metrică
z_var = calc_zscore(chan_var);
z_max = calc_zscore(chan_max);
z_kurt = calc_zscore(chan_kurtosis);

% Identificarea canalelor proaste
bad_var_idx = find(abs(z_var) > thresh_z);
bad_max_idx = find(abs(z_max) > thresh_z);
bad_kurt_idx = find(abs(z_kurt) > thresh_z);

% Extragerea numelor canalelor proaste
bad_channels_var = data.label(bad_var_idx);
bad_channels_max = data.label(bad_max_idx);
bad_channels_kurt = data.label(bad_kurt_idx);

% Combinarea tuturor canalelor proaste detectate
all_bad_channels = unique([bad_channels_var; bad_channels_max; bad_channels_kurt]);

fprintf('Canale proaste detectate (varianță): %d\n', length(bad_channels_var));
fprintf('Canale proaste detectate (amplitudine max): %d\n', length(bad_channels_max));
fprintf('Canale proaste detectate (kurtosis): %d\n', length(bad_channels_kurt));
fprintf('Canale proaste detectate (total unic): %d\n', length(all_bad_channels));

if ~isempty(all_bad_channels)
    disp('Canale proaste detectate:');
    disp(all_bad_channels);
else
    disp('Nu s-au detectat canale proaste!');
end

% Eliminarea canalelor proaste
cfg = [];
cfg.channel = setdiff(data.label, all_bad_channels);
if length(cfg.channel) < length(data.label)
    data_clean_channels = ft_selectdata(cfg, data);
    fprintf('Au fost eliminate %d canale proaste.\n', length(data.label) - length(data_clean_channels.label));
else
    data_clean_channels = data;
    fprintf('Nu au fost eliminate canale.\n');
end

%% Pasul 2: Detectarea automată a segmentelor proaste

fprintf('\n=== PASUL 2: DETECTAREA AUTOMATĂ A SEGMENTELOR PROASTE ===\n');

% Calculul valorilor standard pentru fiecare segment
ntrials = length(data_clean_channels.trial);
trial_var = zeros(ntrials, 1);
trial_max = zeros(ntrials, 1);
trial_range = zeros(ntrials, 1);

for i = 1:ntrials
    trial_var(i) = var(data_clean_channels.trial{i}(:));
    trial_max(i) = max(abs(data_clean_channels.trial{i}(:)));
    trial_range(i) = range(data_clean_channels.trial{i}(:));
end

% Identificarea segmentelor proaste bazate pe z-score
% Folosim funcția manuală de calcul z-score în loc de zscore()
trial_var_z = calc_zscore(trial_var);
trial_max_z = calc_zscore(trial_max);
trial_range_z = calc_zscore(trial_range);

% Pragul pentru identificarea segmentelor proaste
threshold = 3; % z-score de 3 standard deviations

% Găsirea segmentelor proaste
bad_trials_var = find(abs(trial_var_z) > threshold);
bad_trials_max = find(abs(trial_max_z) > threshold);
bad_trials_range = find(abs(trial_range_z) > threshold);

% Combinarea tuturor segmentelor proaste
all_bad_trials = unique([bad_trials_var; bad_trials_max; bad_trials_range]);

fprintf('Segmente proaste detectate (varianță): %d\n', length(bad_trials_var));
fprintf('Segmente proaste detectate (amplitudine): %d\n', length(bad_trials_max));
fprintf('Segmente proaste detectate (interval): %d\n', length(bad_trials_range));
fprintf('Segmente proaste detectate (total unic): %d\n', length(all_bad_trials));

% Eliminarea segmentelor proaste
if ~isempty(all_bad_trials)
    good_trial_idx = setdiff(1:ntrials, all_bad_trials);
    
    cfg = [];
    cfg.trials = good_trial_idx;
    data_clean = ft_selectdata(cfg, data_clean_channels);
    
    fprintf('Au fost eliminate %d segmente proaste.\n', length(all_bad_trials));
else
    data_clean = data_clean_channels;
    fprintf('Nu au fost eliminate segmente.\n');
end

%% Pasul 3: Aplicarea referinței medii

fprintf('\n=== PASUL 3: APLICAREA REFERINȚEI MEDII ===\n');

cfg = [];
cfg.reref = 'yes';
cfg.refchannel = 'all';    % folosește toate canalele pentru referință
cfg.refmethod = 'avg';     % metodă de referință medie

% Aplică referința medie
data_avg_ref = ft_preprocessing(cfg, data_clean);

fprintf('Referința medie aplicată.\n');

%% Pasul 4: Salvarea rezultatelor

% Salvarea datelor curățate și cu referință medie
save('Dots_30_001_clean_data_auto.mat', 'data_avg_ref', '-v7.3');

% Salvarea informațiilor despre respingere
rejection_info = struct();
rejection_info.bad_channels = all_bad_channels;
rejection_info.bad_trials = all_bad_trials;
rejection_info.initial_channels = length(data.label);
rejection_info.kept_channels = length(data_clean.label);
rejection_info.initial_segments = length(data.trial);
rejection_info.kept_segments = length(data_clean.trial);
rejection_info.var_metrics = metrics_var;
rejection_info.kurt_metrics = metrics_kurt;
rejection_info.max_metrics = metrics_max;

save('Dots_30_001_rejection_info_auto.mat', 'rejection_info');

fprintf('\nProcesul de respingere automată și aplicare a referinței medii s-a încheiat cu succes!\n');
fprintf('Datele curățate au fost salvate în "Dots_30_001_clean_data_auto.mat"\n');
fprintf('Informațiile despre respingere au fost salvate în "Dots_30_001_rejection_info_auto.mat"\n');

%% Pasul 5: Vizualizarea comparativă (opțional)

% Pentru a vizualiza datele înainte și după curățare, rulează aceste comenzi separat:
% 
% % Vizualizarea datelor originale
% cfg = [];
% cfg.viewmode = 'vertical';
% cfg.continuous = 'no';
% cfg.blocksize = 0.5;
% ft_databrowser(cfg, data_original);
% 
% % Vizualizarea datelor curățate cu referință medie
% cfg = [];
% cfg.viewmode = 'vertical';
% cfg.continuous = 'no';
% cfg.blocksize = 0.5;
% ft_databrowser(cfg, data_avg_ref);