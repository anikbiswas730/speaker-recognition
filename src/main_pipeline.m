% =========================================================================
% main_pipeline.m
% Main Execution Pipeline — Text-Independent Speaker Recognition
%
% Description:
%   Loads pre-recorded audio files for all enrolled speakers, extracts
%   acoustic features (MFCCs + pitch) in 10-second frames, computes mean
%   feature vectors, and classifies an unknown test recording by finding
%   the minimum Mahalanobis distance to each enrolled speaker's template.
%
%   Run this script after collecting audio with record_test.m.
%   Ensure all .wav files are placed in ../data/samples/
%
% File Naming Convention:
%   <ROLL>_1.wav  — Training/reference sample for speaker <ROLL>
%   <ROLL>_2.wav  — Test/evaluation sample   for speaker <ROLL>
%
% Authors: EEE-312 Group (Rolls: 1906125, 1906126, 1906127, 1906128)
% Course:  EEE-312 Digital Signal Processing Lab, BUET
% =========================================================================

clc;
clear all;
close all;

%% -------------------------------------------------------------------------
%  CONFIGURATION
% -------------------------------------------------------------------------
DATA_DIR         = fullfile('..', 'data', 'samples');
FRAME_LENGTH_SEC = 10;    % Analysis window (seconds)

% Speaker registry: {Roll, Display Name}
SPEAKERS = {
    '1906125', 'Speaker A';
    '1906126', 'Speaker B';
    '1906127', 'Speaker C';
    '1906128', 'Speaker D';
};
NUM_SPEAKERS = size(SPEAKERS, 1);

fprintf('============================================================\n');
fprintf('  Speaker Recognition System — EEE-312 BUET\n');
fprintf('============================================================\n\n');

%% -------------------------------------------------------------------------
%  PHASE 1: FEATURE EXTRACTION — REFERENCE TEMPLATES
% -------------------------------------------------------------------------
fprintf('--- Phase 1: Building Reference Templates ---\n');

ref_mfcc  = cell(NUM_SPEAKERS, 1);   % Store mean MFCC matrix per speaker
ref_pitch = cell(NUM_SPEAKERS, 1);   % Store mean pitch vector per speaker

for spk = 1:NUM_SPEAKERS
    roll = SPEAKERS{spk, 1};
    name = SPEAKERS{spk, 2};

    wav_path = fullfile(DATA_DIR, sprintf('%s_1.wav', roll));

    if ~isfile(wav_path)
        warning('Reference file not found: %s — skipping %s.', wav_path, name);
        continue;
    end

    [y, fs] = audioread(wav_path);
    fprintf('Processing reference for %s (%s)...\n', name, roll);

    [mean_mfcc, mean_pitch] = extract_mean_features(y, fs, FRAME_LENGTH_SEC);

    ref_mfcc{spk}  = mean_mfcc;
    ref_pitch{spk} = mean_pitch;

    fprintf('  -> Extracted %d MFCC dims, %d pitch frames.\n\n', ...
            size(mean_mfcc, 2), length(mean_pitch));
end

%% -------------------------------------------------------------------------
%  PHASE 2: FEATURE EXTRACTION — TEST SAMPLES
% -------------------------------------------------------------------------
fprintf('--- Phase 2: Extracting Test Features ---\n');

test_mfcc  = cell(NUM_SPEAKERS, 1);
test_pitch = cell(NUM_SPEAKERS, 1);

for spk = 1:NUM_SPEAKERS
    roll = SPEAKERS{spk, 1};
    name = SPEAKERS{spk, 2};

    wav_path = fullfile(DATA_DIR, sprintf('%s_2.wav', roll));

    if ~isfile(wav_path)
        warning('Test file not found: %s — skipping %s.', wav_path, name);
        continue;
    end

    [y, fs] = audioread(wav_path);
    fprintf('Processing test for %s (%s)...\n', name, roll);

    [mean_mfcc, mean_pitch] = extract_mean_features(y, fs, FRAME_LENGTH_SEC);

    test_mfcc{spk}  = mean_mfcc;
    test_pitch{spk} = mean_pitch;
end

%% -------------------------------------------------------------------------
%  PHASE 3: CLASSIFICATION — MAHALANOBIS DISTANCE MATRIX
% -------------------------------------------------------------------------
fprintf('\n--- Phase 3: Classification via Mahalanobis Distance ---\n\n');

dist_mfcc_matrix  = nan(NUM_SPEAKERS, NUM_SPEAKERS);
dist_pitch_matrix = nan(NUM_SPEAKERS, NUM_SPEAKERS);

for test_spk = 1:NUM_SPEAKERS
    if isempty(test_mfcc{test_spk}), continue; end

    for ref_spk = 1:NUM_SPEAKERS
        if isempty(ref_mfcc{ref_spk}), continue; end

        try
            dist_mfcc_matrix(test_spk, ref_spk) = ...
                MahalanobisDistance(test_mfcc{test_spk}, ref_mfcc{ref_spk});

            dist_pitch_matrix(test_spk, ref_spk) = ...
                MahalanobisDistance(test_pitch{test_spk}, ref_pitch{ref_spk});
        catch ME
            warning('Distance computation failed (%s vs %s): %s', ...
                    SPEAKERS{test_spk,1}, SPEAKERS{ref_spk,1}, ME.message);
        end
    end
end

%% -------------------------------------------------------------------------
%  PHASE 4: RESULTS & VISUALISATION
% -------------------------------------------------------------------------
fprintf('--- Phase 4: Results ---\n\n');

speaker_labels = SPEAKERS(:, 2)';

% Combined distance (equal weighting of MFCC and pitch)
combined_dist = 0.7 * dist_mfcc_matrix + 0.3 * dist_pitch_matrix;

fprintf('%-14s | %-12s | %-12s | %-12s | %s\n', ...
    'Test Speaker', 'MFCC Dist', 'Pitch Dist', 'Combined', 'Identified As');
fprintf('%s\n', repmat('-', 1, 72));

correct = 0;
total   = 0;

for test_spk = 1:NUM_SPEAKERS
    if all(isnan(combined_dist(test_spk, :))), continue; end

    [~, best_ref] = min(combined_dist(test_spk, :));
    is_correct    = (best_ref == test_spk);
    correct       = correct + is_correct;
    total         = total + 1;

    status = '';
    if is_correct, status = ' ✓'; else, status = ' ✗'; end

    fprintf('%-14s | %-12.4f | %-12.4f | %-12.4f | %s%s\n', ...
        SPEAKERS{test_spk, 2}, ...
        dist_mfcc_matrix(test_spk, test_spk), ...
        dist_pitch_matrix(test_spk, test_spk), ...
        combined_dist(test_spk, best_ref), ...
        SPEAKERS{best_ref, 2}, status);
end

fprintf('\n Overall Accuracy: %d / %d (%.1f%%)\n\n', ...
        correct, total, 100 * correct / max(total, 1));

%% --- Distance Heatmap ---
figure('Name', 'Mahalanobis Distance Matrix', 'NumberTitle', 'off', ...
       'Position', [100 100 900 380]);

subplot(1, 2, 1);
imagesc(dist_mfcc_matrix);
colorbar; colormap('hot');
xticks(1:NUM_SPEAKERS); xticklabels(speaker_labels);
yticks(1:NUM_SPEAKERS); yticklabels(speaker_labels);
title('MFCC Distance Matrix');
xlabel('Reference Speaker'); ylabel('Test Speaker');

subplot(1, 2, 2);
imagesc(dist_pitch_matrix);
colorbar; colormap('hot');
xticks(1:NUM_SPEAKERS); xticklabels(speaker_labels);
yticks(1:NUM_SPEAKERS); yticklabels(speaker_labels);
title('Pitch Distance Matrix');
xlabel('Reference Speaker'); ylabel('Test Speaker');

sgtitle('Mahalanobis Distance Matrices — Lower = More Similar');

%% =========================================================================
%  LOCAL HELPER: extract_mean_features
% =========================================================================
function [mean_mfcc, mean_pitch] = extract_mean_features(y, fs, frame_sec)
% Extract and accumulate mean MFCC and pitch features across all frames.

    frame_length = frame_sec * fs;
    num_frames   = floor(length(y) / frame_length);

    acc_mfcc  = [];
    acc_pitch = [];

    for i = 1:num_frames
        frame_start = (i - 1) * frame_length + 1;
        frame_end   = i * frame_length;
        frame       = y(frame_start : frame_end);

        try
            [mfccs, ~, ~, ~, pit] = extract_mfcc_features(frame, fs);
            acc_mfcc  = [acc_mfcc;  mfccs'];   %#ok<AGROW>
            acc_pitch = [acc_pitch; pit];        %#ok<AGROW>
        catch ME
            warning('Feature extraction failed on frame %d: %s', i, ME.message);
        end
    end

    mean_mfcc  = acc_mfcc;
    mean_pitch = acc_pitch;

    % If only one frame, replicate row for covariance computation
    if size(mean_mfcc, 1) < 2
        mean_mfcc  = repmat(mean_mfcc,  2, 1);
        mean_pitch = repmat(mean_pitch, 2, 1);
    end
end
