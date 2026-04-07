function [mfccs, spec_centroid, spec_rolloff, zcr, pit] = extract_mfcc_features(sig, fs)
% EXTRACT_MFCC_FEATURES  Comprehensive acoustic feature extraction pipeline.
%
%   [mfccs, spec_centroid, spec_rolloff, zcr, pit] = extract_mfcc_features(sig, fs)
%
%   Preprocesses the input audio signal and extracts a set of acoustic
%   features suitable for text-independent speaker recognition.
%
%   Inputs:
%       sig  - Raw audio signal vector (time domain)
%       fs   - Original sampling frequency in Hz
%
%   Outputs:
%       mfccs        - Matrix of MFCC coefficients (12 x num_frames)
%       spec_centroid- Spectral centroid values per frame
%       spec_rolloff - Spectral roll-off point values per frame
%       zcr          - Zero-crossing rate per frame
%       pit          - Estimated fundamental frequency (pitch) per frame (Hz)
%
%   Processing Steps:
%       1. Amplitude normalisation to [-1, 1]
%       2. Resampling from fs to 16 kHz (Nyquist satisfied for speech < 8 kHz)
%       3. MFCC extraction via custom mfcc() function
%       4. Spectral descriptor extraction via MATLAB Audio Toolbox
%       5. Pitch estimation via MATLAB's built-in YIN-based pitch()
%
%   Authors: EEE-312 Group (Rolls: 1906125, 1906126, 1906127, 1906128)
%   Course:  EEE-312 Digital Signal Processing, BUET

    TARGET_FS  = 16000;   % Target sampling frequency after downsampling
    N_COEFFS   = 12;      % Number of MFCC coefficients to retain

    %% --- 1. Preprocessing ---
    sig = normalize(sig);               % Normalise amplitude to [-1, 1]
    sig = resample(sig, TARGET_FS, fs); % Downsample to 16 kHz

    %% --- 2. MFCC Extraction ---
    ceps  = mfcc(sig, TARGET_FS);       % Custom MFCC implementation
    mfccs = ceps(1:N_COEFFS, :);        % Retain first N_COEFFS coefficients

    %% --- 3. Spectral Features ---
    % Spectral Centroid — centre of mass of the spectrum (brightness)
    spec_centroid = spectralCentroid(sig, TARGET_FS);

    % Spectral Roll-off — frequency below which 85% of energy is contained
    spec_rolloff = spectralRolloffPoint(sig, TARGET_FS);

    %% --- 4. Temporal Feature ---
    % Zero-Crossing Rate — number of sign changes per frame (voicing indicator)
    zcr = zero_crossing_rate(sig, TARGET_FS);

    %% --- 5. Pitch Estimation ---
    % MATLAB's pitch() uses the YIN algorithm by default.
    % Range 80–400 Hz covers male (80–180 Hz) and female (165–400 Hz) speech.
    pit = pitch(sig, TARGET_FS, ...
        'Method',   'SRH', ...
        'Range',    [80, 400], ...
        'WindowLength', round(TARGET_FS * 0.04), ...
        'OverlapLength', round(TARGET_FS * 0.02));

end
