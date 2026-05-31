
prefixes = {'A', 'B', 'C', 'D'};
numCh = 32; 
all_data_mat= [];

for p = 1:length(prefixes)
    for i = 1:numCh
        fname = sprintf('Dots_30_001-%s%d.bin', prefixes{p}, i);
        if exist(fname, 'file')
            fid = fopen(fname, 'r');
            ch_data = fread(fid, 'float32'); 
            fclose(fid);
            all_data_mat = [all_data_mat, ch_data];
        else
            fprintf('Lipseste %s\n', fname)
        end
    end
end

% matricea cu toate canalele
save('Dots_30_001_all_channels.mat', 'all_data_mat');
    