function m = melFilterBank(p, n, fs)
% MELFILTERBANK  Generate a sparse Mel-spaced triangular filterbank matrix.
%
%   m = melFilterBank(p, n, fs)
%
%   Constructs the matrix M of size (p × (1 + floor(n/2))) whose rows
%   represent triangular bandpass filters spaced uniformly on the Mel scale.
%   The output is a MATLAB sparse matrix for computational efficiency.
%
%   Inputs:
%       p   - Number of filters in the filterbank (e.g., 20 or 40)
%       n   - FFT length (must match the frame size used in mfcc.m)
%       fs  - Sampling frequency in Hz
%
%   Output:
%       m   - Sparse matrix of filterbank amplitudes, size [p, 1+floor(n/2)]
%             Multiply m by the one-sided power spectrum to get mel energies.
%
%   Mel Scale Relationship:
%       mel(f) = 2595 * log10(1 + f/700)
%       inv:  f = 700 * (10^(mel/2595) - 1)
%
%   Implementation Note:
%       The frequency axis is mapped via the relation:
%           f0 = 700 / fs   (normalised breakpoint)
%       Logarithmic spacing is then computed using:
%           lr = log(1 + 0.5/f0) / (p + 1)
%       which distributes p+1 equally-spaced intervals on the log-mel axis
%       between DC and the Nyquist bin.
%
%   Authors: EEE-312 Group (Rolls: 1906125–1906128), BUET
%   Original formulation adapted from standard MFCC literature.

    f0  = 700 / fs;           % Normalised mel breakpoint
    fn2 = floor(n / 2);       % Highest useful FFT bin index (Nyquist)

    % Log-mel spacing step size
    lr  = log(1 + 0.5 / f0) / (p + 1);

    % FFT bin boundaries for the filter edges in continuous (non-integer) bins
    % bl(1): lower edge of filter 1  (DC-side)
    % bl(2): centre of filter 1
    % bl(3): centre of filter p
    % bl(4): upper edge of filter p  (Nyquist-side)
    bl = n * (f0 * (exp([0, 1, p, p+1] * lr) - 1));

    b1 = floor(bl(1)) + 1;                     % First active bin
    b2 = ceil(bl(2));                           % Lower filter rises from here
    b3 = floor(bl(3));                          % Upper filter falls to here
    b4 = min(fn2, ceil(bl(4))) - 1;            % Last active bin (clip at Nyquist)

    % Fractional bin positions mapped to filter indices
    pf = log(1 + (b1:b4) / n / f0) / lr;
    fp = floor(pf);
    pm = pf - fp;                               % Linear interpolation weight

    % Build sparse matrix entries:
    %   r = filter row index
    %   c = FFT bin column index (+1 for MATLAB 1-based indexing)
    %   v = filter amplitude (triangular shape via linear interp)
    r = [fp(b2:b4),    1 + fp(1:b3)];
    c = [(b2:b4),      (1:b3)] + 1;
    v = 2 * [(1 - pm(b2:b4)),  pm(1:b3)];

    m = sparse(r, c, v, p, 1 + fn2);

end
