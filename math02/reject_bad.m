% 1. respingerea manuala a canalelor 'bad'
% 2. identificarea cananlelor 'bad' 
% 3. aplicarea referintei medii 

%data.label: numele canalelor 
%data.trial: datele EEG pentru fiecare segment
%data.time: vectorii de timp pentru fiecare segment
%data.fsample: rata de eșantionare 


addpath('/Users/alinamacavei/Desktop/NEUROSCIENCE/fieldtrip-doc/fieldtrip-20250106');
ft_defaults;

fprintf('INCARC SEGMENTELE de la segmentation.m ...\n') ; 
load('Dots_30_001_segments.mat');

data=[]; 
data.fsample = fs;

%etichetarea canalelor  -> numele lor 'chan081'
data.label = cell(size(segments,2),1); % (segments,2) = nr canale EEG + ,1 => o coloana 

for i = 1 : size(segments,2)
    data.label{i} = sprintf('chan%03d', i);
end


%structura pt trials si time 
data.trial = cell(size(segments,3),1); 
data.time = cell(size(segments,3),1);

%%%%% STANDARD FieldTrip ---->   [canale x time]
% transferul datelor in format FieldTrip

for i = 1: size(segments,3) % 4938 de segmente 
    data.trial{i} = squeeze(segments(:, :, i))'; % transpunere (')
    data.time{i} = (0:size(segments,1)-1) / fs; 
end

%verificare 
data_original = data ; 

fprintf('chan005, chan015, chan016, chan017, chan071\n');


cfg = [];
cfg.viewmode = 'vertical';
cfg.continuous = 'no';
cfg.blocksize = 0.5;
cfg.channel = 'all';
ft_databrowser(cfg, data);

% P1: respingerea manuala 'BAD CHANNELS'
cfg = [];
cfg.method = 'summary'; % 
cfg.keepchannel = 'no'; 
data_clean_channels = ft_rejectvisual(cfg, data);
fprintf('\nCanale respinse: %d\n', length(rejected_channels));

% P2 : respingerea manuala 'BAD SEGMENTS'
cfg = [];
cfg.method = 'summary';
cfg.keepchannel = 'yes';
cfg.keeptrial = 'no';

data_clean = ft_rejectvisual(cfg, data_clean_channels);
fprintf('\nSegmente inițiale: %d\n', length(data_clean_channels.trial));
fprintf('Segmente păstrate: %d\n', length(data_clean.trial));
fprintf('Segmente respinse: %d\n', length(data_clean_channels.trial) - length(data_clean.trial));

% P3: aplicarea referintei medii
cfg = [];
cfg.reref = 'yes';
cfg.refchannel = 'all';

data_avg_ref = ft_preprocessing(cfg, data_clean);

save('Dots_30_001_clean_data.mat', 'data_avg_ref', '-v7.3');
fprintf('Respingere manuala a canalelor bad , DONE !\n');
 