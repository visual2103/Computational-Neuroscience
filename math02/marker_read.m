timestamps_file = 'Dots_30_001-Event-Timestamps.bin';
codes_file = 'Dots_30_001-Event-Codes.bin';

if ~isfile(timestamps_file)
    error(['Fisierul ', timestamps_file, ' nu exista!']);
end

if ~isfile(codes_file)
    error(['Fisierul ', codes_file, ' nu exista!']);
end

fid_timestamps = fopen(timestamps_file, 'r');


timestamps = fread(fid_timestamps, inf, 'int32'); 
if isempty(timestamps)
    error('empty file timestamps');
end


fid_codes = fopen(codes_file, 'r');
event_codes = fread(fid_codes, inf, 'int32'); 
fclose(fid_codes);


if isempty(event_codes)
   error('empty file event_codes');
end
fclose(fid_timestamps);

if length(timestamps) ~= length(event_codes)
    error("!!!!!!!  timestamps != nr de event_codes    !!!!!!");
end


markers = [timestamps, event_codes];
disp('Markerii incarcati , DONE !');