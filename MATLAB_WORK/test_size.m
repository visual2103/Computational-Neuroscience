for p = 1:length(prefixes)
    for i = 1:numCh
        fname = sprintf('Dots_30_001-%s%d.bin', prefixes{p}, i);
        if exist(fname, 'file')
            fid = fopen(fname, 'r');
            ch_data = fread(fid, 'float32'); 
            fclose(fid);
            fprintf('Canal %s%d, lungime: %d\n', prefixes{p}, i, length(ch_data));
        end
    end
end
