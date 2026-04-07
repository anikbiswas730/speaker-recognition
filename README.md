#  Robust Text-Independent Speaker Recognition
### MFCC + Mahalanobis Distance | EEE-312 DSP Project | BUET

> A MATLAB implementation of a text-independent speaker identification system using
> Mel-Frequency Cepstral Coefficients (MFCCs), pitch tracking, and Mahalanobis
> distance classification — developed for the EEE-312 Digital Signal Processing
> sessional at Bangladesh University of Engineering and Technology.

---

##  Table of Contents
- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Requirements](#requirements)
- [Quick Start](#quick-start)
- [How It Works](#how-it-works)
- [File Reference](#file-reference)
- [Results](#results)
- [Authors](#authors)

---

## Overview

Speaker recognition is the biometric task of identifying a person from their voice.
This project implements a **text-independent** system — the speaker can say anything,
and the system will still identify them based on the physiological characteristics of
their vocal tract.

### Key Features
- Custom **MFCC** extractor with Mel filterbank (no Audio Toolbox dependency for core DSP)
- **YIN/SRH-based pitch tracking** (80–400 Hz range)
- **Mahalanobis distance** classifier accounting for feature correlations
- Modular design: each DSP stage is a separate, well-documented `.m` function
- Works with **4 speakers** out of the box; easily extensible

---

## Repository Structure

```
speaker-recognition/
│
├── src/                          # All MATLAB source files
│   ├── record_test.m             # 1. Audio data acquisition
│   ├── extract_mfcc_features.m   # 2. Feature extraction wrapper
│   ├── mfcc.m                    # 3. Core MFCC algorithm
│   ├── melFilterBank.m           # 4. Mel filterbank generator
│   ├── MahalanobisDistance.m     # 5. Mahalanobis distance classifier
│   ├── main_pipeline.m           # 6. End-to-end pipeline script
│   └── zero_crossing_rate.m      #    Helper: zero-crossing rate
│
├── data/
│   └── samples/                  # Place .wav files here
│       ├── 1906125_1.wav         # Speaker 1 — reference
│       ├── 1906125_2.wav         # Speaker 1 — test
│       └── ...
│
├── docs/
│   └── SYSTEM_DESIGN.md          # Detailed architecture documentation
│
├── .gitignore
└── README.md
```

---

## Requirements

| Requirement | Version |
|-------------|---------|
| MATLAB | R2021a or later |
| Signal Processing Toolbox | Any recent version |
| Audio Toolbox *(optional)* | For `spectralCentroid`, `spectralRolloffPoint`, `pitch` |

> **Note:** The core MFCC computation (`mfcc.m`, `melFilterBank.m`) has **no toolbox
> dependency**. Only the supplementary spectral features in `extract_mfcc_features.m`
> require the Audio Toolbox.

---

## Quick Start

### Step 1 — Record Training Data
```matlab
cd src/

% Edit SPEAKER_ID and SAMPLE_NUM inside the script, then:
record_test        % Records a 2-minute training sample
```
Repeat for each of the 4 speakers (set `SAMPLE_NUM = 1` for reference, `2` for test).

### Step 2 — Run the Pipeline
```matlab
main_pipeline      % Extracts features, builds templates, classifies, plots results
```

### Step 3 — Read the Output
The console will print a results table:
```
Test Speaker   | MFCC Dist    | Pitch Dist   | Combined     | Identified As
------------------------------------------------------------------------
Speaker A      | 1.2341       | 0.8723       | 1.0252       | Speaker A ✓
Speaker B      | 2.1047       | 1.3341       | 1.8746       | Speaker B ✓
...
Overall Accuracy: 4 / 4 (100.0%)
```

---

## How It Works

### Signal Flow
```
WAV File → Normalise → Resample (16 kHz) → Frame (10 s windows)
   → MFCC (12 coeffs) + Pitch (F0)
   → Mean Feature Matrix per Speaker
   → Mahalanobis Distance to each Reference Template
   → Minimum Distance → Predicted Speaker
```

### MFCC Extraction Steps
1. **Framing** — 256-sample frames with 100-sample step (≈61% overlap)
2. **Hamming Window** — minimises spectral leakage at frame edges
3. **FFT** — convert to frequency domain
4. **Mel Filterbank** — 20 triangular filters on Mel scale (perceptual warping)
5. **Log Compression** — compress dynamic range
6. **DCT** — decorrelate filterbank energies → 12 cepstral coefficients

### Classification
The Mahalanobis distance between test feature matrix **B** and reference matrix **A**:

```
d = √[ (μ_A − μ_B) · Cp⁻¹ · (μ_A − μ_B)ᵀ ]

where  Cp = (n₁/n)·Σ_A + (n₂/n)·Σ_B  (pooled covariance)
```

The test speaker is assigned the identity of the reference template with **minimum d**.

---

## File Reference

| File | Description |
|------|-------------|
| `record_test.m` | Records mono audio at 44.1 kHz/16-bit and saves to `data/samples/` |
| `extract_mfcc_features.m` | Wrapper: normalise → resample → MFCC + pitch + spectral features |
| `mfcc.m` | Core MFCC: framing, Hamming window, FFT, Mel filterbank, log-DCT |
| `melFilterBank.m` | Generates sparse triangular Mel filterbank matrix (p × N/2+1) |
| `MahalanobisDistance.m` | Pooled covariance Mahalanobis distance with dimension checks |
| `main_pipeline.m` | Full pipeline: loads WAVs, extracts features, classifies, plots |
| `zero_crossing_rate.m` | Frame-wise zero-crossing rate computation |

For detailed mathematical documentation, see [`docs/SYSTEM_DESIGN.md`](docs/SYSTEM_DESIGN.md).

---

## Results

The system achieves robust speaker discrimination for 4 speakers:
- Adding **pitch (F0)** alongside the 12 MFCCs significantly reduces the false acceptance rate.
- **10-second frame integration** smooths transient fluctuations for stable feature clusters.
- **Mahalanobis distance** outperforms Euclidean distance, especially when background noise skews spectral centroid variance.

---

## Authors

| Roll | Department |
|------|------------|
| 1906125 | Electrical & Electronic Engineering, BUET |
| 1906126 | Electrical & Electronic Engineering, BUET |
| 1906127 | Electrical & Electronic Engineering, BUET |
| 1906128 | Electrical & Electronic Engineering, BUET |

**Supervisor:** Lecturer Shahed Ahmed, EEE Department, BUET

**Course:** EEE-312 — Digital Signal Processing Laboratory

---

## References

1. L. Rabiner and B. Juang, *Fundamentals of Speech Recognition*, Prentice-Hall, 1993.
2. A. V. Oppenheim and R. W. Schafer, *Discrete-Time Signal Processing*, 2nd ed., Prentice-Hall, 1999.
3. S. Davis and P. Mermelstein, "Comparison of parametric representations for monosyllabic word recognition," *IEEE Trans. ASSP*, vol. 28, no. 4, pp. 357–366, 1980.
4. A. de Cheveigné and H. Kawahara, "YIN, a fundamental frequency estimator for speech and music," *JASA*, vol. 111, no. 4, pp. 1917–1930, 2002.
5. R. O. Duda, P. E. Hart, and D. G. Stork, *Pattern Classification*, 2nd ed., Wiley, 2001.
