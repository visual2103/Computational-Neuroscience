cfg=[];
cfg.dataset = '/Users/alinamacavei/Desktop/NEUROSCIENCE/DataSet/Dots_30_001/Dots_30_001.eegex';
event = ft_read_event(cfg.dataset);
event(1:5)
values=cell(1,numel(event));
for i =1:numel(event)
    values{i} = event(i).value; 
end 
unique(values)