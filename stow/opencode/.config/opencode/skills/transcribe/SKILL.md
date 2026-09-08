---
name: transcribe
description: Transcribe audio/video to text or SRT using Mistral Voxtral API (no local models). Use when the user asks to transcribe, subtitle, caption, extract text from audio/video, or "que dice este video/audio".
---

# transcribe

Cloud transcription via Mistral Voxtral. No local models.

## Pipeline

```bash
# 1. Audio extraction (if video): yt-dlp downloads, ffmpeg extracts/converts
ffmpeg -i input.mp4 -vn -ac 1 -ar 16000 output.mp3

# 2. Plain transcript
curl -s https://api.mistral.ai/v1/audio/transcriptions \
  -H "Authorization: Bearer $MISTRAL_API_KEY" \
  -F file=@output.mp3 -F model=voxtral-mini-latest

# 3. With word timestamps -> build SRT from segments
curl -s https://api.mistral.ai/v1/audio/transcriptions \
  -H "Authorization: Bearer $MISTRAL_API_KEY" \
  -F file=@output.mp3 -F model=voxtral-mini-latest \
  -F timestamp_granularities=segment
```

## Rules

- Convert to mono 16kHz mp3 first (smaller upload, faster).
- Files >25MB: split with `ffmpeg -ss <start> -t <dur>` before sending.
- Download step for URLs: `mise exec -- yt-dlp -x --audio-format mp3 <url>`.
- Save transcripts next to source as `<name>.transcript.md`, SRT as `<name>.srt`.
- Model alternatives: `voxtral-small-latest` (higher quality), `voxtral-mini-latest` (fast).
