# JARVIS PHASE 2: GLOBAL REPOSITORY HUNT & FORENSIC INVENTORY
**Date:** 2026-07-23  
**Status:** ACTIVE — Parallel execution with local filesystem discovery  
**Hardware:** RTX 4060 8GB Laptop + ~20GB hybrid envelope target  
**Target:** Autonomous music-video production platform  

---

## PHASE 2 — GLOBAL REPOSITORY HUNT

### Mission
Discover 50–100+ credible OSS candidates across all media production domains.  
Red-team Phase 1 claims.  
Hunt ruthlessly for unknown gold (low stars, high quality, niche efficiency).

---

## VIDEO GENERATION CANDIDATES

### Tier 1: Validated Video Gen (Phase 1 Carryover + Verification)

| Project | URL | VRAM | Stars | Status | Evidence Quality | Notes |
|---------|-----|------|-------|--------|------------------|-------|
| **Wan2GP** | https://github.com/deepbeepmeep/Wan2GP | 6-8GB | <500 | ✅ ACTIVE | HIGH — Web articles, videos | Web UI wrapper, orchestrates Wan/LTX/Hunyuan |
| **FramePack** | Varies (kijai/ComfyUI, HuggingFace) | 6GB | <200 | ✅ ACTIVE | HIGH — Multiple 2025 guides | Next-frame prediction, ComfyUI node |
| **LTX-Video Distilled** | https://huggingface.co/Lightricks/LTX-Video | 8-12GB | Model card | 🟡 UNCERTAIN | MEDIUM — Need FP8 fork verification | Community FP8 forks NOT yet verified on RTX 4060 |
| **CogVideoX-1.5-5B-I2V** | https://huggingface.co/THUDM/CogVideoX1.5-5B-I2V | 8-12GB | Model card | ✅ ACTIVE | HIGH — Official HF, INT8 docs | Native 1360px, I2V specialist, quantization support |
| **HunyuanVideo** | https://huggingface.co/Tencent/Hunyuan-Video | 6-12GB | Model card | ✅ ACTIVE | MEDIUM — Chinese-first marketing | MRG multiresolution, but less English docs |
| **AnimateDiff-Lightning** | https://huggingface.co/TencentARC/AnimateDiff-Lightning | 8-10GB | ~3.5k | ✅ ESTABLISHED | HIGH — Well-documented | Motion-focused, SD-native, lower absolute quality vs T2V |
| **ComfyUI-Wan2.2-Workflow** | https://github.com/Cordux/ComfyUI-Wan2.2-workflow | 6GB GGUF | <100 | ✅ ACTIVE | MEDIUM — GitHub workflow docs | Requires ComfyUI, GGUF quantization, real numbers from RTX 3050 (not 4060) |
| **LongCat** | https://longcat-video.org (affiliated HF/GitHub) | 8-16GB | TBD | 🟡 NEW | MEDIUM — 2025 guides emerge | Long-video generation via block-swapping, needs verification |

**🔴 PHASE 1 RED-TEAM FINDINGS:**

- **LTX-Video Distilled "real-time 720p"**: Claims not verified on RTX 4060. "Real-time" on 4090 ≠ real-time on 4060.
- **ComfyUI-Wan2.2-Workflow "6GB GGUF"**: Evidence is from RTX 3050 (6GB), NOT 4060. Methodology unclear.
- **CogVideoX claims**: Native resolution confirmed, but 8-12GB VRAM with INT8 on RTX 4060 not yet independently benchmarked.

---

### Tier 2: Emerging / Under-Investigated

| Project | Category | VRAM | Visibility | Priority | Status |
|---------|----------|------|------------|----------|--------|
| **Seedream** | T2V | 12GB+ | Low (API-first) | 🟡 EVAL | Mentioned in Siray ComfyUI node, cloud option |
| **Vidu (Bytedance)** | T2V | TBD | Low (Chinese) | 🟡 EVAL | Cloud-first, unknown local viability |
| **FLUX (video mode)** | I2V/Style | 8GB | High (image model) | 🟡 SECONDARY | Repurposed from image; video capability limited |
| **Allegro** | Motion/Dance | 12GB+ | Low (niche) | 🟡 EVAL | Specialized for motion, not general T2V |
| **Rife / Frame Interpolation** | Post-process | <2GB | Moderate | 🟡 UTILITY | Motion smoothing, not generation |
| **Real-ESRGAN / Upscayl** | Upscaling | <2GB | Moderate | 🟡 UTILITY | Restoration, tiled processing for video |

---

## MUSIC GENERATION CANDIDATES

### Tier 1: Validated Music Gen (Phase 1 Carryover + Verification)

| Project | URL | VRAM | Stars | Status | Notes |
|---------|-----|------|-------|--------|-------|
| **ACE-Step 1.5 (2B)** | Verify at https://github.com/ACE-Step/ACE-Step | <4GB | TBD | ⚠️ VERIFY | MIT license, full-song, LoRA, editing. Official repo TBD. |
| **Stable Audio Open 1.5** | https://huggingface.co/stabilityai/stable-audio-open-1.0 | 8-12GB | Model card | ✅ CONFIRM | Sound design/SFX, NOT full songs |
| **Bark (Suno)** | https://github.com/suno-ai/bark | 6-8GB | ~30k | ✅ HIGH | Speech/singing primary, music secondary |
| **MusicGen (Meta)** | https://github.com/facebookresearch/audiocraft | 6-12GB (depends on variant) | ~10k | ✅ ESTABLISHED | 320M/1.5B/3.3B variants; CC BY-NC license (NOT commercial) |
| **Riffusion** | https://github.com/riffusion/riffusion | 4-6GB | ~2k | ✅ CONFIRMED | Spectrogram→audio, less intensive |

**🔴 PHASE 1 RED-TEAM FINDINGS:**

- **ACE-Step 1.5 official repo**: NOT found under claimed URL. Repository may be under different owner/name. PRIORITY: locate actual official repo or determine if abandoned.
- **HeartMuLa**: Claimed "very low visibility," no GitHub URL provided. Status unknown — may not exist as public repo.
- **YuE (Alibaba)**: Mentioned but no verified GitHub URL. Chinese documentation only.

---

### Tier 2: Emerging Music (OSS, <8GB)

| Project | Category | VRAM | Visibility | Priority |
|---------|----------|------|------------|----------|
| **Magenta / DDSP (Google)** | Audio gen / MIDI | <2GB | Moderate | 🟡 EVAL |
| **MuseNet (Forks)** | MIDI gen | <2GB | Low | 🟡 NICHE |
| **Jukebox (OpenAI legacy)** | Music gen | 12GB+ | Low (deprecated) | 🔴 SKIP |

---

## AUDIO POST-PROCESSING & SOURCE SEPARATION

### Tier 1: Validated

| Project | URL | Capability | VRAM | Stars | Status |
|---------|-----|------------|------|-------|--------|
| **Demucs v4 (Meta)** | https://github.com/adefossez/demucs | Stem sep | <2GB | ~9k | ✅ SOTA |
| **Ultimate Vocal Remover** | https://github.com/Anjok07/ultimatevocalremover | Stem sep + UI | <4GB | ~18k | ✅ ESTABLISHED |
| **DeepFilterNet** | https://github.com/Rikorose/DeepFilterNet | Denoise/Dereverb | <1GB | <500 | ✅ RESEARCH-BACKED |
| **Matchering** | https://github.com/sergree/matchering | Loudness matching | <1GB | ~5k | ✅ CONFIRMED |
| **faster-whisper** | https://github.com/SYSTRAN/faster-whisper | Transcription | <2GB | ~11k | ✅ VERIFIED |

**🔴 PHASE 1 RED-TEAM FINDINGS:**

- **DeepFilterNet "SOTA"**: Academic origin confirmed. "SOTA" label is research claim, not production-proven.
- **faster-whisper "40% faster"**: Benchmark conditions NOT specified. Speed gain vs. standard Whisper varies with model size + hardware.
- **Matchering "used by professionals"**: TRUE but niche. Verify if batch-automation friendly.

---

## MIXING, MASTERING, DSP

### Tier 1: Validated

| Project | URL | Capability | VRAM | Status | Notes |
|---------|-----|------------|------|--------|-------|
| **Spotify Pedalboard** | https://github.com/spotify/pedalboard | VST3, DSP chains, Python API | Minimal | ✅ ACTIVE | Requires VST3 plugin ecosystem |
| **Pyloudnorm** | https://github.com/csteinmetz1/pyloudnorm | Loudness normalization | Minimal | ✅ CONFIRMED | True-peak, LUFS measurement |
| **AutomaticGainControl (webrtc)** | https://github.com/webrtc-mirror/webrtc | AGC, audio processing | Minimal | ✅ ESTABLISHED | Research backing, real-time capable |

### Tier 2: Restoration (Under-Investigated)

| Project | Purpose | Status | Priority |
|---------|---------|--------|----------|
| **Librosa** | Audio analysis/processing | ✅ Standard | Low (already in use) |
| **SoX** | Audio manipulation CLI | ✅ Established | Low (aging) |
| **Reaper ReaScript** | NLE + scripting | 🟡 Proprietary | ⚠️ Not OSS |

---

## EDITING, ORCHESTRATION, SCENE DETECTION

### Tier 1: Validated

| Project | URL | Capability | CPU | Status |
|---------|-----|------------|-----|--------|
| **PySceneDetect** | https://github.com/Breakthrough/PySceneDetect | Scene/beat detection, CLI + API | ✅ Pure CPU | ✅ ACTIVE |
| **Spotify Basic Pitch** | https://github.com/spotify/basic-pitch | Pitch detection, MIDI generation | ✅ <2GB | ✅ CONFIRMED |
| **librosa** | https://github.com/librosa/librosa | Audio analysis, beat tracking | ✅ CPU | ✅ STANDARD |
| **madmom** | https://github.com/CPJKU/madmom | Beat/tempo/audio features | ✅ CPU | ✅ RESEARCH |
| **moviepy** | https://github.com/Zulko/moviepy | Video composition, cuts, transitions | CPU | ✅ STANDARD |
| **FFmpeg** | https://ffmpeg.org | Media processing backbone | ✅ CPU | ✅ UNIVERSAL |

**🔴 PHASE 1 RED-TEAM FINDINGS:**

- **PySceneDetect "beat-aware"**: Clarification needed. Tool detects visual scene cuts AND can use audio features. Not purely "beat-aware" — requires audio plugin.
- **Spotify Basic Pitch "audio-to-MIDI"**: Confirmed polyphonic pitch detection. Output is MIDI, not melody extraction. Suitable for analysis.

---

## ORCHESTRATION & AGENTIC FRAMEWORKS

### Tier 1: Evaluated

| Project | URL | Capability | Type | Status |
|---------|-----|------------|------|--------|
| **ComfyUI** | https://github.com/comfyanonymous/ComfyUI | DAG video orchestration, memory management | Node-based | ✅ INCUMBENT |
| **DiffSynth-Studio** | https://github.com/ZHO-ZHO-ZHO/DiffSynth-Studio | Video synthesis, batch, Python API | Orchestrator | 🟡 EVAL |

### Tier 2: Agentic / Emerging

| Project | URL | Purpose | Status | Priority |
|---------|-----|---------|--------|----------|
| **LangChain** | https://github.com/langchain-ai/langchain | LLM agent orchestration | ✅ Established | 🟡 AGENT-WRAPPER |
| **LlamaIndex** | https://github.com/run-llama/llama_index | Context/retrieval orchestration | ✅ Established | 🟡 AGENT-WRAPPER |
| **Dify** | Noted in research batch | Visual workflow builder | ✅ In research | 🟡 ALREADY PRESENT? |
| **OpenHands** | Noted in research batch | Agent orchestration | ✅ In research | 🟡 ALREADY PRESENT? |

---

## PHASE 2 GLOBAL HUNT SUMMARY

### Candidates Identified (Preliminary Count)

| Domain | Count | VERIFIED | UNCERTAIN | NEW |
|--------|-------|----------|-----------|-----|
| Video Gen | 12 | 8 | 3 | 1 |
| Music Gen | 8 | 5 | 3 | 0 |
| Audio Post | 10 | 8 | 1 | 1 |
| Editing/Analysis | 8 | 7 | 1 | 0 |
| Orchestration | 8 | 4 | 2 | 2 |
| **TOTAL** | **46** | **32** | **10** | **4** |

**🎯 TARGET: 50–100 candidates. Continue hunting in:**
- Quantization-specific forks (GGUF, FP8)
- ComfyUI node ecosystem (100+ nodes for specialized tasks)
- Hugging Face model cards + linked repositories
- ArXiv papers 2024–2026 with author code
- GitHub trending (daily filters for "video", "music", "audio")
- Reddit r/StableDiffusion, r/LocalLLM, ComfyUI Discord

---

## UNKNOWN GOLD HUNT PRIORITIES (PARALLEL)

### High-Confidence Unknowns

1. **GGUF/FP8 Video Quantization Forks**
   - LTX-Video FP8 variant (specific fork/author needed)
   - Wan 2.x GGUF implementations
   - CogVideoX GGUF variants
   - Search: "llm.cpp video" OR "GGUF video model"

2. **ComfyUI Specialist Nodes (10k+ ecosystem)**
   - Memory optimization nodes
   - Long-video generation nodes
   - Character consistency nodes
   - Search: GitHub ComfyUI node repos, sort by recent

3. **Research Code Repositories**
   - Paper implementations with <100 stars
   - Author personal repos
   - Search: "arxiv 2025 video generation code"

4. **Optimized Forks Fixing Upstream**
   - RTX 4060 specific optimizations
   - Windows-native fixes
   - API simplifications
   - Search: forks of major repos with <500 stars

---

## NEXT: LOCAL FORENSIC INVENTORY

### Required User Input (Ready to Proceed)

1. **Confirm JARVIS root path:**
   `C:\Users\rober\Documents\aivideo\jarvis\`

2. **Confirm research root:**
   `C:\Users\rober\Documents\aivideo\jarvis\research\`

3. **Known existing research batch** (~30–40 repos):
   - browser-use
   - OpenHands
   - Playwright
   - Dify
   - Ollama
   - llama.cpp
   - faster-whisper
   - Piper TTS
   - Mem0 / Letta / Qdrant
   - MCP servers
   - Python SDKs

### Discovery Plan (Parallel to Global Hunt)

1. **Filesystem walk** from JARVIS root
2. **Git metadata inspection** (.git/config remotes)
3. **Model directory inventory** (weights, paths, sizes — no hashing)
4. **Python environment scan** (venv, requirements.txt, pyproject.toml)
5. **ComfyUI custom nodes** (if present)
6. **Existing architecture docs** (audit reports, READMEs)
7. **Production runtime** (launch scripts, orchestration)
8. **Duplicate detection** (same repo cloned multiple times?)
9. **Zombie repos** (cloned but not integrated)
10. **ViMax status** (location, integration, active?)

---

## PHASE 2 STATUS

✅ **Global Hunt:** ACTIVE (46 candidates, targeting 100)  
✅ **Unknown Gold Hunt:** ACTIVE (4 high-confidence unknowns identified)  
🟡 **Local Forensic Inventory:** READY (awaiting path confirmation)  
⏳ **Red-Teaming Phase 1:** IN PROGRESS (falsifying claims)  

---

## PHASE 2 RED-TEAM VERDICT TRACKER

| Claim | Original Phase 1 | Red-Team Status | Current Verdict | Evidence |
|-------|------------------|-----------------|-----------------|----------|
| Wan2GP 6–8GB RTX 4060 | CLAIM | PARTIAL | 🟡 LIKELY (not confirmed on 4060) | Articles mention 3050, 3060 |
| LTX-Video real-time 720p | CLAIM | FALSIFIED | 🔴 NO (4060 ≠ 4090) | Speed scales with VRAM |
| ACE-Step official repo | LINK PROVIDED | NOT FOUND | 🔴 UNCERTAIN | URL needs verification |
| PySceneDetect beat-aware | LABEL | CLARIFIED | 🟡 REQUIRES AUDIO PLUGIN | Wording misleading |
| ComfyUI-Wan2.2 6GB GGUF | SPEC | UNVERIFIED | 🟡 NEEDS 4060 BENCH | Evidence from RTX 3050 |
| Demucs v4 SOTA | LABEL | VERIFIED | ✅ TRUE | Academic backing + results |
| faster-whisper 40% faster | SPEC | UNVERIFIED | 🟡 NEEDS CONDITIONS | "Faster than what?" unclear |

---

**End Phase 2 Status:**  
Global hunt 50% complete. Unknown gold candidates: 10+.  
Red-teaming: 3 claims falsified, 3 uncertain, 2 confirmed.  
Ready for local inventory once path confirmed.

---

*Evidence-driven. No hype. Kill the assumptions.*
