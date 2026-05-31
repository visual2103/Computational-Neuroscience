
function out = plot_qc_and_conditions(inFile, opts)
% PLOT_QC_AND_CONDITIONS  Quick QC + ERP plots from epoched EEG (.mat)
%
% Usage:
%   plot_qc_and_conditions;                     % choose file via dialog
%   plot_qc_and_conditions('Dots_30_001_epochs_203trials_718smp_128ch.mat');
%   plot_qc_and_conditions('file.mat', struct('roi_idx', 65:96, 'save_pdf', true));
%
% Expects .mat with variables: ep_data [nSamp x nChan x nTrials], ti_keep (table), meta (struct).
% meta.time should be a time vector in seconds; if missing, it will be derived from meta.winSamp/meta.fs.

%% ---- Parse inputs
if ~exist('inFile','var') || isempty(inFile)
    [f, p] = uigetfile('*.mat', 'Alege fișierul epocat (.mat)');
    if isequal(f,0), disp('Anulat.'); return; end
    inFile = fullfile(p,f);
end
if ~exist('opts','var') || isempty(opts)
    opts = struct();
end
if ~isfield(opts, 'roi_idx'),            opts.roi_idx = []; end   % default: all channels
if ~isfield(opts, 'save_dir'),           opts.save_dir = ''; end  % default: next to file
if ~isfield(opts, 'save_pdf'),           opts.save_pdf = true; end
if ~isfield(opts, 'save_png'),           opts.save_png = false; end
if ~isfield(opts, 'sort_by_rt'),         opts.sort_by_rt = true; end
if ~isfield(opts, 'auto_best_window'),   opts.auto_best_window = [0 0.300]; end  % seconds
if ~isfield(opts, 'cond_key'),           opts.cond_key = 'G'; end
if ~isfield(opts, 'pdf_name'),           opts.pdf_name = 'qc_plots.pdf'; end

[matDir, matName] = fileparts(inFile);
if isempty(opts.save_dir), opts.save_dir = fullfile(matDir, 'figures'); end
if ~exist(opts.save_dir, 'dir'), mkdir(opts.save_dir); end
pdfPath = fullfile(opts.save_dir, opts.pdf_name);

%% ---- Load data
S = load(inFile);
need = {'ep_data', 'ti_keep', 'meta'};
for k = 1:numel(need)
    if ~isfield(S, need{k})
        error('Fișierul nu conține variabila obligatorie "%s".', need{k});
    end
end
ep_data = S.ep_data;          % [nSamp x nChan x nTrials], single/double
ti_keep = S.ti_keep;          % table
meta    = S.meta;             % struct

[nSamp, nChan, nTrials] = size(ep_data);
fprintf('Loaded: %s | %d samples x %d channels x %d trials\n', matName, nSamp, nChan, nTrials);

% time vector (sec)
if isfield(meta,'time') && ~isempty(meta.time)
    time = meta.time(:);
elseif isfield(meta,'winSamp') && isfield(meta,'fs')
    time = meta.winSamp(:) ./ meta.fs;
elseif isfield(meta,'fs')
    % fallback: assume -0.2..0.5 sec as earlier code
    time = linspace(-0.2, 0.5, nSamp).';
    warning('Nu am găsit meta.time sau meta.winSamp; folosesc fallback -0.2..0.5 s.');
else
    error('Nu pot deriva vectorul de timp (lipsește meta.fs).');
end

% ROI default = toate canalele
if isempty(opts.roi_idx)
    opts.roi_idx = 1:nChan;
end
roi_idx = opts.roi_idx(:)';
roi_idx = roi_idx(roi_idx>=1 & roi_idx<=nChan);
if isempty(roi_idx)
    error('ROI invalid după filtrare. Verifică indicii.');
end

%% ---- Helper: figure saver
figN = 0;
if exist(pdfPath, 'file'), delete(pdfPath); end
saveFig = @(h, baseName) local_save_figure(h, baseName, opts.save_dir, pdfPath, opts.save_pdf, opts.save_png);

%% ---- 1) Butterfly (medie pe trialuri pentru fiecare canal)
erp_ch = mean(ep_data, 3);  % [nSamp x nChan]
figN = figN + 1; h = figure('Name', sprintf('%02d_Butterfly', figN), 'Color','w'); 
plot(time*1000, erp_ch, 'LineWidth', 0.8); grid on
xlabel('Timp (ms)'); ylabel('\muV'); title('Butterfly (medie pe trialuri, toate canalele)');
xline(0,'k:');
saveFig(h, sprintf('%02d_butterfly', figN));

%% ---- 2) Alege canalul "cel mai informativ" și plotează ERP + ERPimage
win = opts.auto_best_window;
postMask = time >= win(1) & time <= win(2);
% energy across time in window, averaged across trials
rms_post = squeeze(sqrt(mean(mean(ep_data(postMask,:,:).^2, 1), 3))); % [nChan x 1]
[~, ch_best] = max(rms_post);

% ERP pe canalul selectat
erp_best = mean(ep_data(:, ch_best, :), 3);  % [nSamp x 1]
figN = figN + 1; h = figure('Name', sprintf('%02d_ERP_best_channel', figN), 'Color','w');
plot(time*1000, erp_best, 'LineWidth', 1.8); grid on
xlabel('Timp (ms)'); ylabel('\muV');
title(sprintf('ERP canal %d (ales automat, %.0f–%.0f ms)', ch_best, win(1)*1000, win(2)*1000));
xline(0,'k:');
saveFig(h, sprintf('%02d_erp_best_ch%03d', figN, ch_best));

% ERPimage (trial x timp), sortat după RT dacă există
order = 1:nTrials;
if opts.sort_by_rt && istable(ti_keep) && any(strcmpi('ResponseTimeuS', ti_keep.Properties.VariableNames))
    rt = ti_keep.ResponseTimeuS;
    try
        [~, order] = sort(rt, 'ascend', 'MissingPlacement','last');
    catch
        [~, order] = sort(rt, 'ascend');
    end
end
erpimg = squeeze(ep_data(:, ch_best, order))';   % [trial x time]
figN = figN + 1; h = figure('Name', sprintf('%02d_ERPimage', figN), 'Color','w');
imagesc(time*1000, 1:size(erpimg,1), erpimg);
axis xy; colorbar; xlabel('Timp (ms)'); ylabel('Trial');
ttl = sprintf('ERPimage canal %d', ch_best);
if exist('rt','var') && ~isempty(rt), ttl = [ttl ' (sortat după RT)']; end
title(ttl); xline(0,'w:');
saveFig(h, sprintf('%02d_erpimage_ch%03d', figN, ch_best));

%% ---- 3) ERP pe condiții (ex: G) pe ROI
condKey = opts.cond_key;
hasCond = false;
if istable(ti_keep) && any(strcmp(condKey, ti_keep.Properties.VariableNames))
    levels = unique(round(ti_keep.(condKey), 3));
    if ~isempty(levels) && ~all(isnan(levels))
        hasCond = true;
        figN = figN + 1; h = figure('Name', sprintf('%02d_ERP_conditions', figN), 'Color','k'); hold on
        legtxt = strings(0,1);
        for i = 1:numel(levels)
            sel = abs(round(ti_keep.(condKey),3) - levels(i)) < 1e-6;
            if ~any(sel), continue; end
            erp_roi = mean(mean(ep_data(:, roi_idx, sel), 2), 3); % [nSamp x 1]
            plot(time*1000, erp_roi, 'LineWidth', 1.6);
            legtxt(end+1) = sprintf('%s=%.2f (n=%d)', condKey, levels(i), sum(sel)); %#ok<AGROW>
        end
        grid on; xlabel('Timp (ms)'); ylabel('\muV');
        title(sprintf('ERP pe condiții (medie ROI: %d canale)', numel(roi_idx)));
        xline(0,'k:'); legend(legtxt, 'Location','best');
        saveFig(h, sprintf('%02d_erp_conditions_%s', figN, condKey));
    end
end

%% ---- 4) QC numeric: baseline & SNR pe canal + histogram
preMask  = time >= -0.200 & time < 0;      % baseline
postMask = time >=  0.050 & time <= 0.250; % fereastră tipică P1/N1
erp_ch   = mean(ep_data, 3);               % [nSamp x nChan]
rms_pre  = sqrt(mean(erp_ch(preMask,:).^2, 1));
rms_post2 = sqrt(mean(erp_ch(postMask,:).^2, 1));
snr_ch   = rms_post2 ./ (rms_pre + eps);

base_mean_abs = mean(abs(mean(erp_ch(preMask,:),1)));
fprintf('QC: |baseline mean| pe canale = %.3f µV\n', base_mean_abs);
fprintf('QC: SNR median (0.05–0.25s vs pre) = %.2f\n', median(snr_ch));

figN = figN + 1; h = figure('Name', sprintf('%02d_SNR_hist', figN), 'Color','k');
histogram(snr_ch, max(10, round(sqrt(numel(snr_ch)))));
xlabel('SNR canale'); ylabel('Frecvență'); grid on
title('Distribuția SNR-ului pe canale (0.05–0.25s vs -0.2–0s)');
saveFig(h, sprintf('%02d_snr_hist', figN));

%% ---- Pack outputs
out = struct();
out.best_channel = ch_best;
out.snr_channel  = snr_ch;
out.roi_idx      = roi_idx;
out.has_conditions = hasCond;
out.baseline_mean_abs_uV = base_mean_abs;
out.auto_best_window_s   = win;
out.file = inFile;
out.save_dir = opts.save_dir;
if opts.save_pdf, out.pdf = pdfPath; else, out.pdf = ''; end

fprintf('Gata. Figurile au fost salvate în: %s\n', opts.save_dir);
if opts.save_pdf && exist(pdfPath,'file')
    fprintf('PDF compus: %s\n', pdfPath);
end

end % function


function local_save_figure(h, baseName, saveDir, pdfPath, savePDF, savePNG)
% Helper to save a figure as PNG and/or append to a multi-page PDF
drawnow;
pngPath = fullfile(saveDir, [baseName '.png']);
if savePNG
    try
        exportgraphics(h, pngPath, 'Resolution', 180);
    catch
        print(h, pngPath, '-dpng', '-r180');
    end
end
if savePDF
    try
        exportgraphics(h, pdfPath, 'Append', true);
    catch
        % fallback for older MATLAB: save individual PDFs
        print(h, fullfile(saveDir, [baseName '.pdf']), '-dpdf', '-bestfit');
    end
end
end

