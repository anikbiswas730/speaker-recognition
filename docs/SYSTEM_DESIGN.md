# System Design — Speaker Recognition via MFCC & Mahalanobis Distance

## Overview

This document describes the internal architecture of the text-independent speaker recognition system developed for EEE-312 (Digital Signal Processing) at BUET.

---

## 1. System Architecture

```
Raw Audio (.wav)
      │
      ▼
┌─────────────────────┐
│   Preprocessing     │  Normalise amplitude → Resample 44.1 kHz → 16 kHz
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│  Feature Extraction │
│  ─────────────────  │
│  • MFCC (12 coeff) │
│  • Pitch / F0      │
│  • Spec. Centroid  │
│  • Spec. Rolloff   │
│  • ZCR             │
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│ Frame Aggregation   │  Mean feature vector over 10-second frames
└─────────┬───────────┘
          │
          ▼
┌─────────────────────┐
│   Classification    │  Mahalanobis Distance to each enrolled template
└─────────┬───────────┘
          │
          ▼
   Predicted Speaker Identity
```

---

## 2. Signal Preprocessing

| Step | Operation | Rationale |
|------|-----------|-----------|
| Normalisation | Scale to [−1, 1] | Remove gain variation across microphones |
| Resampling | 44.1 kHz → 16 kHz | Human speech energy concentrated below 8 kHz; reduces FFT cost |

---

## 3. MFCC Pipeline Detail

### 3.1 Framing
The signal is divided into overlapping frames:
- **Frame size (N):** 256 samples ≈ 16 ms at 16 kHz
- **Step size (M):** 100 samples ≈ 6.25 ms at 16 kHz (≈61% overlap)

### 3.2 Hamming Windowing
Each frame is multiplied by a Hamming window to reduce spectral leakage:
```
w(n) = 0.54 − 0.46 · cos(2π·n / (N−1))
```

### 3.3 Mel Filterbank
Twenty triangular bandpass filters are spaced uniformly on the Mel scale:
```
mel(f) = 2595 · log₁₀(1 + f/700)
```
The filterbank matrix **M** (20 × 129) is sparse for efficiency.

### 3.4 DCT
The Discrete Cosine Transform decorrelates log-filterbank energies:
```
c_k = Σ_{j=1}^{P} log(E_j) · cos(πk/P · (j − 0.5))
```
The first 12 coefficients are retained; C₀ is discarded.

---

## 4. Pitch Estimation

MATLAB's built-in `pitch()` function implements the **Subharmonic-to-Harmonic Ratio (SRH)** method. The search range is bounded to **80–400 Hz** to cover both male (80–180 Hz) and female (165–400 Hz) fundamental frequency ranges.

---

## 5. Classification

### Mahalanobis Distance
Given reference matrix **A** (n₁ × k) and test matrix **B** (n₂ × k):

**Pooled covariance:**
```
Cp = (n₁/n)·Σ_A + (n₂/n)·Σ_B
```

**Distance:**
```
d = √[ (μ_A − μ_B) · Cp⁻¹ · (μ_A − μ_B)ᵀ ]
```

The test recording is assigned to the speaker with the **minimum** combined distance:
```
d_combined = 0.7 · d_MFCC + 0.3 · d_pitch
```

### Why Not Euclidean Distance?
Acoustic features have different scales and are correlated. Euclidean distance treats all dimensions equally and ignores covariance. Mahalanobis distance normalises by the covariance matrix, making it scale-invariant and statistically principled.

---

## 6. File Descriptions

| File | Role |
|------|------|
| `record_test.m` | Records audio from microphone, saves `.wav` |
| `extract_mfcc_features.m` | Feature extraction wrapper (all features) |
| `mfcc.m` | Core MFCC computation (framing → DCT) |
| `melFilterBank.m` | Generates sparse Mel filterbank matrix |
| `MahalanobisDistance.m` | Computes pooled Mahalanobis distance |
| `main_pipeline.m` | End-to-end training, testing, and classification |
| `zero_crossing_rate.m` | Helper: frame-wise ZCR computation |

---

## 7. Limitations & Future Work

- **Dataset size:** Only two 2-minute samples per speaker. More data would yield more stable covariance estimates.
- **Noise robustness:** No noise suppression or spectral subtraction is applied. Adding VAD (Voice Activity Detection) would improve performance in noisy environments.
- **Classifier:** Mahalanobis distance is a single-template metric. A Gaussian Mixture Model (GMM) would capture intra-speaker variability more accurately.
- **Cepstral mean subtraction (CMS):** Applying CMS would reduce channel effects from different microphones.
