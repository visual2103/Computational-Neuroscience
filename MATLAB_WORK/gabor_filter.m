% Incarcă imaginea ta
img = imread('brain.png');      % Inlocuieste cu numele fișierului tău!
if size(img,3) == 3                % Dacă imaginea e color
    img = rgb2gray(img);           % Convertește la alb-negru
end
img = im2double(img);              % Normalizează valorile între 0 și 1

% Parametri pentru filtrul Gabor
theta = pi/2;      % Orientare: verticală
lambda = 8;        % Lungime undă (frecvență)
sigma = 4;         % Lățime Gaussiană
gamma = 0.5;       % Raport de aspect
psi = 0;           % Fază

% Dimensiunea filtrului
sz = 31; % trebuie să fie impar
[x, y] = meshgrid(-floor(sz/2):floor(sz/2), -floor(sz/2):floor(sz/2));

% Rotire axe după orientare
x_theta = x * cos(theta) + y * sin(theta);
y_theta = -x * sin(theta) + y * cos(theta);

% Formula filtrului Gabor 2D
gb = exp(-0.5*(x_theta.^2 + (gamma^2)*(y_theta.^2))/sigma^2) ...
    .* cos(2*pi*x_theta/lambda + psi);

% Aplică filtrul pe imagine (convoluție 2D)
resp = conv2(img, gb, 'same');

% Afișare rezultate
figure;
subplot(1,3,1); imshow(img, []); title('Imagine încărcată');
subplot(1,3,2); imagesc(gb); axis image; colorbar; title('Filtru Gabor');
subplot(1,3,3); imshow(resp, []); title('Răspuns după convoluție');
