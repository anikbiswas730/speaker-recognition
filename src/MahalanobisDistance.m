function d = MahalanobisDistance(A, B)
% MAHALANOBISDISTANCE  Compute the pooled Mahalanobis distance between
%                      two multivariate data matrices.
%
%   d = MahalanobisDistance(A, B)
%
%   Returns the Mahalanobis distance between the empirical distributions
%   of A and B, normalised by their pooled covariance matrix. This metric
%   is scale-invariant and accounts for inter-feature correlations, making
%   it far superior to Euclidean distance for high-dimensional acoustic
%   feature spaces.
%
%   Inputs:
%       A  - Reference feature matrix  (n1 observations × k features)
%            Rows are observations (frames), columns are features (MFCCs).
%       B  - Test/query feature matrix (n2 observations × k features)
%
%   Output:
%       d  - Scalar Mahalanobis distance ≥ 0.
%            A smaller d indicates greater similarity between speakers.
%
%   Mathematical Formulation:
%       Pooled covariance:
%           Cp = (n1/(n1+n2)) * Σ_A  +  (n2/(n1+n2)) * Σ_B
%
%       Distance:
%           d = sqrt( (µ_A - µ_B) * Cp^{-1} * (µ_A - µ_B)^T )
%
%   Error Handling:
%       - Emits an error if A and B have different numbers of features (k).
%       - Warns if the pooled covariance matrix is singular or near-singular
%         (condition number > 1e12), which can occur with very short samples.
%
%   Authors: Kardi Teknomo (original), Anik (co-author, adaptation)
%            EEE-312 Group (Rolls: 1906125–1906128), BUET
%
%   Reference:
%       Duda, Hart & Stork, Pattern Classification, 2nd ed., Wiley, 2001.

    [n1, k1] = size(A);
    [n2, k2] = size(B);
    n = n1 + n2;

    %% --- Dimension Check ---
    if k1 ~= k2
        error('MahalanobisDistance:dimensionMismatch', ...
              'A and B must have the same number of feature columns (got %d vs %d).', ...
              k1, k2);
    end

    %% --- Pooled Covariance Matrix ---
    xDiff = mean(A, 1) - mean(B, 1);   % 1 × k mean difference row vector
    cA    = cov(A);                      % k × k covariance of reference
    cB    = cov(B);                      % k × k covariance of test

    % Weighted average covariance (weighted by sample sizes)
    pC = (n1 / n) * cA + (n2 / n) * cB;

    %% --- Condition Number Warning ---
    condNum = cond(pC);
    if condNum > 1e12
        warning('MahalanobisDistance:singularCovariance', ...
                'Pooled covariance matrix is near-singular (cond = %.2e). ', ...
                'Results may be unreliable. Consider using more frames.', condNum);
    end

    %% --- Mahalanobis Distance ---
    d = sqrt(xDiff * inv(pC) * xDiff');  %#ok<MINV>
    % Note: inv() used for clarity. For large k, use: d = sqrt(xDiff / pC * xDiff')

end
