function D = compute_pairwise_distance(X, Y)
    % efficient implementation taken from homework assignment 7
    if( ~isa(X,'double') || ~isa(Y,'double'))
        error( 'Inputs must be of type double'); end;
    m = size(X,1); n = size(Y,1);  
    Yt = Y';  
    XX = sum(X.*X,2);        
    YY = sum(Yt.*Yt,1);      
    D = XX(:,ones(1,n)) + YY(ones(1,m),:) - 2*X*Yt;
end