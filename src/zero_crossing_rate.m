function zcr = zero_crossing_rate(sig, fs)
% ZERO_CROSSING_RATE  Compute the zero-crossing rate for overlapping frames.
%
%   zcr = zero_crossing_rate(sig, fs)
%
%   The zero-crossing rate (ZCR) measures how frequently the signal changes
%   sign within a frame. It is a simple time-domain feature used to
%   discriminate voiced speech (low ZCR) from unvoiced segments and silence
%   (high ZCR).
%
%   Inputs:
%       sig  - Input audio signal vector (should be normalised)
%       fs   - Sampling frequency in Hz (used to set frame/step sizes)
%
%   Output:
%       zcr  - Column vector of zero-crossing rates, one value per frame.
%              Units: zero-crossings per sample (normalised).
%
%   Frame Parameters (consistent with mfcc.m):
%       Window length : 25 ms  (fs * 0.025 samples)
%       Step size     : 10 ms  (fs * 0.010 samples)
%
%   Authors: EEE-312 Group (Rolls: 1906125–1906128), BUET

    sig = sig(:);  % Ensure column vector

    %% --- Frame Parameters ---
    win_len  = round(fs * 0.025);   % 25 ms window
    hop_len  = round(fs * 0.010);   % 10 ms hop

    num_frames = 1 + floor((length(sig) - win_len) / hop_len);
    zcr = zeros(num_frames, 1);

    %% --- Compute ZCR Per Frame ---
    for i = 1:num_frames
        start_idx   = (i - 1) * hop_len + 1;
        end_idx     = start_idx + win_len - 1;

        frame = sig(start_idx : end_idx);

        % Count sign changes: XOR of consecutive sample signs
        signs  = sign(frame);
        signs(signs == 0) = 1;   % Treat zero samples as positive

        crossings   = sum(abs(diff(signs))) / 2;
        zcr(i)      = crossings / win_len;  % Normalise by frame length
    end

end
