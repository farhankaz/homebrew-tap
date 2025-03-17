# Homebrew Tap - farhankaz/tap

This repository contains [Homebrew](https://brew.sh/) formulas for various tools developed by farhankaz.

## Usage

Add this tap to your Homebrew installation:

```bash
brew tap farhankaz/tap
```

Then you can install any of the formulas listed below.

## Available Formulas

### llx

A Unix-based system utility for interacting with LLM models using llama.cpp.

**Repository:** [https://github.com/farhankaz/llx](https://github.com/farhankaz/llx)

**Installation:**

```bash
brew install farhankaz/tap/llx
```

**Features:**
- Built on top of llama.cpp for efficient local LLM inference
- Supports Apple Silicon Macs (arm64)
- Requires macOS Ventura or later

**Dependencies:**
- cmake (build)
- curl
- git

## License

All formulas in this repository are licensed under the MIT License.