fs = 1024; 
segment_duration_ms = 500; 
num_samp = round(segment_duration_ms * fs / 1000); 

fname = 'Dots_30_001_all_channels_filtered_v2.mat';
if exist(fname,'file') ~= 2
    error('Fisierul nu exista: %s', fname);
end

eeg_name = 'all_data_filt2'; 
S = load(fname, eeg_name);
X = S.(eeg_name); % EEG

ch_like = [32 64 96 128 256];
[rows, cols] = size(X);
if ismember(rows, ch_like) && ~ismember(cols, ch_like)
    X = X.';    % transpunem; acum [mostre x canale]
elseif ~(rows > cols) && ~ismember(cols, ch_like)
    % in caz de dubiu, alegem orientarea cu mai multe mostre pe prima dimensiune
    if cols > rows, X = X.'; end
end

[num_samples, num_channels] = size(X);
fprintf('EEG selectat: %s [%d mostre x %d canale]\n', eeg_name, num_samples, num_channels);

num_segments = floor(num_samples / num_samp);
%num_segments=floor(2,528,256 / 512) = 4938
fprintf('Nr. segmente: %d (fiecare %d mostre = %d ms)\n', num_segments, num_samp, segment_duration_ms);

segments = zeros(num_samp, num_channels, num_segments, 'like', X);
for i = 1:num_segments
    start_index = (i-1)*num_samp + 1;
    stop_index  = start_index + num_samp - 1;
    segments(:,:,i) = X(start_index:stop_index, :);
end

save('Dots_30_001_segments.mat', 'segments', 'fs', '-v7.3');
fprintf('SEGMENTARE DONE!');
