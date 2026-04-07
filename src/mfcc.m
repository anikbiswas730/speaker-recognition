function c = mfcc(s, fs)
% MFCC  Calculate Mel-Frequency Cepstral Coefficients of a speech signal.
%
%   c = mfcc(s, fs)
%
%   Computes the MFCCs by framing the signal, applying a Hamming window,
%   computing the FFT power spectrum, filtering through a Mel filterbank,
%   taking the log energy, and applying the DCT to decorrelate the outputs.
%
%   Inputs:
%       s   - Input speech signal (column or row vector)
%       fs  - Sampling frequency in Hz
%
%   Outputs:
%       c   - MFCC matrix, each COLUMN contains the feature vector for
%             one speech frame. Size: (p-1) x numberOfFrames
%             (0th cepstral coefficient is excluded as it carries
%              only overall log-energy and is not speaker-discriminative)
%
%   Algorithm:
%       1. Frame the signal with N=256 samples per frame, M=100 step
%       2. Apply Hamming window to each frame
%       3. Compute FFT and extract the one-sided power spectrum
%       4. Pass through 20-channel Mel filterbank (melFilterBank.m)
%       5. Compute log of filterbank energies
%       6. Apply DCT to produce cepstral coefficients
%       7. Remove C0 (index 1 after DCT)
%
%   References:
%       Davis & Mermelstein (1980), IEEE Trans. ASSP, 28(4):357-366.
%
%   Authors: Rakesh (primary), Anik (co-author)
%            EEE-312 Group (Rolls: 1906125–1906128), BUET

    %% --- Parameters ---
    N = 256;     % Frame size (samples) — ~16 ms at 16 kHz
    M = 100;     % Frame step (samples) — ~6.25 ms at 16 kHz (overlap ≈ 61%)
    P = 20;      % Number of Mel filterbank channels

    %% --- 1. Framing ---
    s   = s(:);  % Ensure column vector
    len = length(s);
    numberOfFrames = 1 + floor((len - N) / double(M));

    mat = zeros(N, numberOfFrames);
    for i = 1:numberOfFrames
        startIdx = M * (i - 1) + 1;
        mat(:, i) = s(startIdx : startIdx + N - 1);
    end

    %% --- 2. Windowing ---
    % Hamming window reduces spectral leakage at frame boundaries.
    % w(n) = 0.54 - 0.46 * cos(2*pi*n / (N-1))
    hamW       = hamming(N);
    afterWinMat = diag(hamW) * mat;  % Apply window to each frame column

    %% --- 3. FFT (Frequency Domain) ---
    freqDomMat = fft(afterWinMat);   % N-point FFT for each frame

    %% --- 4. Mel Filterbank ---
    filterBankMat = melFilterBank(P, N, fs);  % P x (1 + N/2) sparse matrix
    nby2 = 1 + floor(N / 2);

    % Compute power spectrum and apply filterbank
    % ms: mel spectrum energies — size (P x numberOfFrames)
    ms = filterBankMat * abs(freqDomMat(1:nby2, :)).^2;

    % Guard against log(0): replace zeros with a small epsilon
    ms(ms < eps) = eps;

    %% --- 5. Log Compression + DCT ---
    % The DCT decorrelates the log-filterbank energies.
    % ck = sum_{j=1}^{P} log(E_j) * cos(pi*k/P * (j - 0.5))
    c = dct(log(ms));

    %% --- 6. Remove C0 ---
    % The zeroth coefficient is proportional to overall log-energy and
    % introduces sensitivity to channel gain — not useful for speaker ID.
    c(1, :) = [];

end
