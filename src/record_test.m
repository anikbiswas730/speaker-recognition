% =========================================================================
% record_test.m
% Data Acquisition Script for Speaker Recognition System
%
% Description:
%   Records a mono audio sample from the system microphone and saves it
%   as a .wav file for use in the speaker recognition pipeline.
%
% Usage:
%   Run this script directly in MATLAB. Adjust SPEAKER_ID and SAMPLE_NUM
%   before each recording session.
%
% Authors: EEE-312 Group (Rolls: 1906125, 1906126, 1906127, 1906128)
% Course:  EEE-312 Digital Signal Processing, BUET
% =========================================================================

clc;
clear all;
close all;

%% --- Configuration ---
SPEAKER_ID  = '1906125';   % Change for each speaker
SAMPLE_NUM  = 1;           % 1 for training sample, 2 for test sample
DURATION    = 120;         % Recording duration in seconds (2 minutes)

%% --- Audio Recording Parameters ---
fs        = 44100;  % Sampling frequency (Hz)
nBits     = 16;     % Bit depth
nChannels = 1;      % Mono recording

%% --- Record Audio ---
fprintf('==============================================\n');
fprintf(' Speaker Recognition — Data Acquisition\n');
fprintf('==============================================\n');
fprintf(' Speaker ID : %s\n', SPEAKER_ID);
fprintf(' Sample     : %d\n', SAMPLE_NUM);
fprintf(' Duration   : %d seconds\n', DURATION);
fprintf('----------------------------------------------\n');
fprintf(' Recording will start in 3 seconds...\n\n');

pause(3);
disp('>>> RECORDING ... Please speak naturally.');

recObj = audiorecorder(fs, nBits, nChannels);
recordblocking(recObj, DURATION);

disp('>>> Recording complete.');

%% --- Retrieve and Save Audio ---
sig = getaudiodata(recObj);

output_filename = sprintf('%s_%d.wav', SPEAKER_ID, SAMPLE_NUM);
output_path     = fullfile('..', 'data', 'samples', output_filename);

audiowrite(output_path, sig, fs);
fprintf('\n Audio saved to: %s\n', output_path);

%% --- Quick Waveform Preview ---
t = (0:length(sig)-1) / fs;
figure('Name', 'Recorded Signal', 'NumberTitle', 'off');
plot(t, sig);
xlabel('Time (s)');
ylabel('Amplitude');
title(sprintf('Waveform — Speaker %s, Sample %d', SPEAKER_ID, SAMPLE_NUM));
grid on;
