
%adaptare 0-127 la 1-128 
occipital_idx = [13,14,15,16,17,21,22,23,24,25,26,27,28,29,30];  % 12 devine 13 etc.
frontal_idx = [77,78,79,80,81,82,83,84,90,91,92,93];
parietal_idx = [1,2,33,34,52,65,66,75,87,88,97,98,111,112];
lefttemporal_idx = [104,105,106,117,118,119,120,121,122,126,127,128];
righttemporal_idx = [42,43,44,46,47,48,56,57,58,59,60,61];

mean_occipital = mean(all_data(:,occipital_idx),2);
mean_frontal = mean(all_data(:,frontal_idx), 2);
mean_parietal = mean(all_data(:,parietal_idx), 2);
mean_lefttemporal = mean(all_data(:,lefttemporal_idx), 2);
mean_righttemporal = mean(all_data(:,righttemporal_idx), 2);

figure;

subplot(5,1,1);plot(mean_occipital); title('Media regiunii OCCIPITAL'); xlabel('Sample'); ylabel('Amplitude');
subplot(5,1,2);plot(mean_frontal); title('Media regiunii FRONTAL'); xlabel('Sample'); ylabel('Amplitude');
subplot(5,1,3);plot(mean_parietal); title('Media regiunii PARIETAL'); xlabel('Sample'); ylabel('Amplitude');
subplot(5,1,4);plot(mean_righttemporal); title('Media regiunii RIGTH TEMPORAL'); xlabel('Sample'); ylabel('Amplitude');
subplot(5,1,5);plot(mean_lefttemporal); title('Media regiunii LEFT TEMPORAL'); xlabel('Sample'); ylabel('Amplitude');

figure;
hold on %suprapunere plot uri 

plot(mean_occipital, 'b');    
plot(mean_frontal, 'r');      
plot(mean_parietal, 'g');     
plot(mean_lefttemporal, 'm'); 
plot(mean_righttemporal, 'k');

legend('Occipital','Frontal','Parietal','Left Temporal','Right Temporal');
xlabel('Sample');
ylabel('Amplitudine');
title('Medii semnal EEG pe regiuni');
hold off
