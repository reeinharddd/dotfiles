---
name: watch-video
description: Make the agent "watch" any video URL - downloads video, extracts frames, gets transcript via watch-cli. Use when the user asks to see/watch/analyze/summarize a video from YouTube, X/Twitter, TikTok, Reddit, Vimeo or extract content/code/architecture from it.
---

# watch-video

Uses watch-cli (`~/.watch-cli`). Output block: VIDEO + FRAMES + TRANSCRIPT.

## Usage

```bash
export PATH="$HOME/.local/bin:$HOME/.local/share/mise/shims:$PATH"
watch '<url>' [frame-count]        # full: download + frames + transcript
dl-video '<url>' [dir]             # only download
extract-frames <video> [count]     # only frames
transcribe <video-or-audio>        # only transcript (--segments-out for SRT)
audio-q <video> "<question>"       # tone/music/SFX Q&A
watch-archive find "<query>"       # search previously watched videos
```

## Rules

- Always quote URLs in single quotes.
- Default frame-count 8; dense UI demos 16-24; short clips 4-6.
- Read FRAMES as images and TRANSCRIPT as text - that is how you "see" the video.
- Repeat watches are cached (~/.watch-cli/archive), no re-download or API cost.
- Prompt library in ~/.watch-cli/prompts/: implement-from-video, extract-architecture,
  clone-ux, paper-to-code, tutorial-walkthrough.
- Transcription backend is Groq BYO (internal to watch-cli); standalone transcription
  tasks should prefer the `transcribe` skill (Mistral Voxtral).
