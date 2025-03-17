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

### snapsense

An intelligent screenshot renaming tool for Apple Silicon Macs using Claude AI.

**Repository:** [https://github.com/farhankaz/snapsense](https://github.com/farhankaz/snapsense)

**Installation:**

```bash
brew install farhankaz/tap/snapsense
```

**Features:**
- Automatically renames screenshots based on their content using Claude AI
- Monitors your Desktop for new screenshots
- Configurable settings

**Dependencies:**
- python@3.12
- uv
- Requires Apple Silicon Mac (arm64)

**Usage:**

Snapsense requires an Anthropic API key to function. Set your API key in your environment:

```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

Commands:
- Start: `snapsense start`
- Check status: `snapsense status`
- Stop: `snapsense stop`
- Edit configuration: `snapsense config`

## License

All formulas in this repository are licensed under the MIT License.