function MR=RescaleMatrix(M,LL,UL)

ML=min(M(:));
MU=max(M(:));

MR=(M-ML)/(MU-ML)*(UL-LL)+LL;

