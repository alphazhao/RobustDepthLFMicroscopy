function matte = three_layer_matting(image, trimap);

% pre-processing
trimap = uint8(ceil((trimap-1).*(127.5)));
image = uint8(image);
I = double(image);
h = fspecial('gaussian',9,0.5);   img_f1 = imfilter(I,h,'replicate');
I = I + (I - img_f1);
trimap = labelExpansion(image,trimap);		% geodesic distance method

% parameters
K0 = 12; K1 = 12; K2 = 7; K3 = 3;
lambda = 1000;  delta = 7;
[m,n,z] = size(image); N = m*n;

msg = 'start building graphs'
% get three layer graph
L1 = getThreeGraph(I,trimap,K0,K1,K2,K3);

msg = 'finished graphs, compute matting Laplacian'
% Computing matting Laplacian
L2 = getColorLineLaplace(I,trimap);

% Computing matte
L = L1 + delta*L2;
M = double(trimap == 255 | trimap == 0);
G = reshape(double(trimap == 255),[],1);
Lambda = lambda*spdiags(M(:),0,N,N);
tol = 1e-7;  maxit = 2000;
Alpha = bicgstab(L+Lambda,Lambda*G,tol,maxit,[],[],double(trimap(:))/255);	%Alpha = pcg(L+Lambda,Lambda*G,tol,maxit);  
Alpha = full(Alpha);
matte = reshape(Alpha,m,n);
matte = max(min(matte,1),0);

% post-processing
matte = imfilter(matte,h,'replicate');