clear ;
clc;
fs = 1024;
USE_500MS_TOTAL = true;        % true -> [-200..+300] ms (~500 ms total)
if USE_500MS_TOTAL
    prestim = 0.200;           % 200 ms pre
    poststim = 0.300;          % 300 ms post
else
    prestim = 0.200;           % pentru P1/N1 extins
    poststim = 0.500;          % 500 ms post
end

sPre  = round(prestim*fs);
sPost = round(poststim*fs);
winSamp = (-sPre : sPost);
time = winSamp/fs;

% P1 : incarc datele filtrate
load Dots_30_001_all_channels_filtered.mat  % -> all_data_filt [N x 128]
if ~exist('all_data_filt','var')
    error('nu gasesc variabila all_data_filt in .mat');
end

[N, nChan] = size(all_data_filt);
fprintf('Loaded filtered data: %d samples x %d channels\n', N, nChan);

%P2 : citesc evenimentele care sunt in binar conform .epd 
fid = fopen('Dots_30_001-Event-Timestamps.bin', 'r');
if fid<0 , error("nu gasesc fisierul cu timestamps "); end
ev_ts = fread(fid,'int32'); 
fclose(fid);

fid = fopen('Dots_30_001-Event-Codes.bin','r');
if fid < 0 , error('nu gasesc fisierul cu codes '); end 
ev_code = fread(fid , 'int32');
fclose(fid);

if numel(ev_ts) ~= numel(ev_code) 
    error('Numarul de timestamp nu corespunde cu numarul de coduri de eveniment');
end
    
fprintf('Am citit %d evenimente. \n',numel(ev_ts)) ; 

% P3: selectez Stimulus ON cu indexul 129 
idx129 = find(ev_code == 129);
% — normalizare timestamp: microsecunde vs indici (0- sau 1-based)
if max(ev_ts) > 1e6        % foarte probabil în microsecunde
    sStim_all = round(double(ev_ts(idx129))/1e6 * fs);
else                        % sunt deja indici
    sStim_all = double(ev_ts(idx129));
    if min(sStim_all) == 0
        sStim_all = sStim_all + 1;  % 0-based -> 1-based
    end
end


nTrials_ev = numel(sStim_all);
fprintf('am gasit %d StimulusON \n', nTrials_ev) ; 

%P4: trail info (csv) + coloanele de care avem nevoie (le verific)
csvFile = 'Dots_30_001-trialinfo.csv' ;
ti = read_trialinfo(csvFile); fprintf('1') ; 

mask_keep = true(height(ti),1);
if ismember('InclEEG', ti.Properties.VariableNames)
    mask_keep = mask_keep & logical(ti.InclEEG);
end
if ismember('InclBehavioral', ti.Properties.VariableNames)
    mask_keep = mask_keep & logical(ti.InclBehavioral);
end
if ismember('FTGood', ti.Properties.VariableNames)
    mask_keep = mask_keep & logical(ti.FTGood);
end
if ismember('GoodTrialsManual', ti.Properties.VariableNames)
    mask_keep = mask_keep & logical(ti.GoodTrialsManual);
end

ti_keep = ti(mask_keep, :);

fprintf('TrialInfo: %d rânduri totale, %d păstrate (după filtre).\n', height(ti), height(ti_keep));



% —— P5: aliniere robustă 129 ↔ ti_keep ——
if height(ti) == numel(sStim_all)
    % 1:1 pe randuri, apoi aplic masca
    sStim_keep = sStim_all(mask_keep);
    ti_keep    = ti(mask_keep, :);
elseif ismember('Trial', ti.Properties.VariableNames)
    % mapare explicita dupa indexul Trial
    ti_keep = ti(mask_keep, :);
    tr = ti_keep.Trial;
    assert(all(tr>=1 & tr<=numel(sStim_all)), 'Trial index out of bounds în sStim_all');
    sStim_keep = sStim_all(tr);
else
    % fallback sigur
    nTrialsMin = min(numel(sStim_all), height(ti_keep));
    ti_keep    = ti_keep(1:nTrialsMin, :);
    sStim_keep = sStim_all(1:nTrialsMin);
end

assert(numel(sStim_keep)==height(ti_keep), 'Misalign între sStim_keep și ti_keep');

% dimensiuni epocare
nSamp   = numel(winSamp);
nTrials = numel(sStim_keep);


ep_data = nan(nSamp, nChan, nTrials, 'single');
bad_tr  = false(nTrials,1);

for t = 1:nTrials
    idx = sStim_keep(t) + winSamp;
    if idx(1) < 1 || idx(end) > N
        bad_tr(t) = true;  % daca iese din capete, marcheaza-l
        continue
    end
    ep_data(:,:,t) = single(all_data_filt(idx, :));
end

% elimină trial-urile out-of-bounds (dacă există)
if any(bad_tr)
    ep_data(:,:,bad_tr) = [];
    ti_keep(bad_tr,:)   = [];
    sStim_keep(bad_tr)  = [];
    nTrials             = size(ep_data,3);
    fprintf('Atenţie: %d epoci eliminate (out-of-bounds). Trialuri rămase: %d\n', sum(bad_tr), nTrials);
end

%% —— Baseline correction pe -200..0 ms ——
baseIdx = 1:sPre;                         % primele sPre eșantioane sunt pre-stim
bl = mean(ep_data(baseIdx,:,:), 1);       % [1 x nChan x nTrials]
ep_data = ep_data - bl;                   % scad baseline-ul

%% —— (opțional) rezumat pe nivel G ——
if ismember('G', ti_keep.Properties.VariableNames)
    [lev,~,levIdx] = unique(round(ti_keep.G,3));
    nPer = accumarray(levIdx, 1);
    fprintf('Trialuri pe nivel G:\n');
    for i=1:numel(lev)
        fprintf('  G = %.2f -> %d trialuri\n', lev(i), nPer(i));
    end
end

meta = struct('fs',fs,'prestim',prestim,'poststim',poststim,'time',time,'winSamp',winSamp);
outFile = sprintf('Dots_30_001_epochs_%dtrials_%dsmp_%dch.mat', size(ep_data,3), nSamp, nChan);
save(outFile, 'ep_data', 'ti_keep', 'sStim_keep', 'meta', '-v7.3');
fprintf('Salvat: %s\n', outFile);

%% —— QC (grand-average) ——
GA = squeeze(mean(mean(ep_data, 2), 3)); % medie pe canale & trialuri
figure; plot(time*1000, GA, 'LineWidth',1.5); grid on
xlabel('Timp (ms)'); ylabel('µV'); title('Grand-average (all channels)');
xline(0,'k:');







function T = read_trialinfo(csvFile)
    % citește CSV-ul, găsește linia reală de header și setează tipurile
    lines = readlines(csvFile);
    hdrIdx = find(contains(lines, "Trial,Filename", 'IgnoreCase', true), 1);
    if isempty(hdrIdx)
        % fallback: caută măcar "Trial,"
        hdrIdx = find(contains(lines, "Trial,", 'IgnoreCase', true), 1);
    end
    if isempty(hdrIdx)
        error('Nu găsesc linia de header în %s', csvFile);
    end

    opts = detectImportOptions(csvFile, 'Delimiter', ',');
    opts.VariableNamesLine = hdrIdx;
    opts.DataLines         = [hdrIdx+1, Inf];

    % asigur *doar* coloanele care există pentru string
    strColsWanted = {'Filename','Stimulus','CorrectResp','Vbresponse'};
    strCols = intersect(strColsWanted, opts.VariableNames, 'stable');
    if ~isempty(strCols)
        opts = setvaropts(opts, strCols, 'Type','string');
    end

    % tip numeric pentru indicii 0/1 și măsurători
    numWanted = {'InclBehavioral','InclPupil','InclFixations','InclEEG','FTGood','G','proc', ...
                 'ResponseID','Accuracy','ResponseTimeuS','Trial'};
    numCols = intersect(numWanted, opts.VariableNames, 'stable');
    for c = numCols
        opts = setvartype(opts, c{1}, 'double');
    end

    T = readtable(csvFile, opts);

    % normalizez eventualele variații de nume (ex. FileName vs Filename)
    vn = string(T.Properties.VariableNames);
    map = containers.Map({'FileName','ResponseTimeus'}, {'Filename','ResponseTimeuS'});
    for k = 1:numel(vn)
        key = char(vn(k));
        if isKey(map, key)
            T.Properties.VariableNames{k} = map(key);
        end
    end
end

assert(size(ep_data,1) == numel(winSamp), 'Dimensiune timp eronată');
assert(size(ep_data,2) == nChan,          'Dimensiune canale eronată');
assert(size(ep_data,3) == height(ti_keep), 'Epoci ≠ rânduri în ti_keep');


% medie pe canale (pentru peak-uri temporale)
GA = squeeze(mean(mean(ep_data, 2), 3));
tms = time*1000;

% ferestre canonice
P1win = [80 130]; N1win = [130 200];

% indici ferestre
iP1 = tms>=P1win(1) & tms<=P1win(2);
iN1 = tms>=N1win(1) & tms<=N1win(2);

% peak-uri pe grand-average
[ampP1, i1] = max(GA(iP1));  tP1 = tms(iP1);  tP1 = tP1(i1);
[ampN1, i2] = min(GA(iN1));  tN1 = tms(iN1);  tN1 = tN1(i2);
fprintf('P1: %+0.2f µV @ %d ms | N1: %+0.2f µV @ %d ms\n', ampP1, round(tP1), ampN1, round(tN1));

% „best channel" pentru P1 (max pozitiv în fereastra P1)
ERPch = squeeze(mean(ep_data,3)); % [nsamp x nChan]
[~, ch_best_P1] = max(max(ERPch(iP1,:),[],1));
[~, ch_best_N1] = min(min(ERPch(iN1,:),[],1));
fprintf('Best channel P1: #%d | Best channel N1: #%d\n', ch_best_P1, ch_best_N1);
figure; plot(tms, ERPch(:,ch_best_P1)); grid on; title(sprintf('ERP canal # %d (P1-best)', ch_best_P1));
xlabel('Timp (ms)'); ylabel('µV'); xline(0,'k:');
