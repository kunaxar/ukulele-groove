
## YouTube song library and audio estimates

Paste a YouTube link at the top. The Cloudflare Worker operates free converter websites in order (yotomp3, then EzConv), streams transient MP3 audio to the browser, and Essentia.js estimates tempo and accent-based strum arrangements from a 60-second section. Audio is not saved in the library. Use only audio you have permission to analyze.

The four strums are possible arrangements, not original strum transcription. The beat confidence display is a relative score, not a probability of accuracy, and does not measure meter or pattern correctness. Meter is a heuristic. Synthesized demos play a C chord, not song chords. Converter encoding can change pattern ranking. YouTube may block embedding or require a bot check.

The library saves URLs, optional titles, estimates and selected patterns locally in this browser. It has no account sync and is lost if site storage is cleared.

### Free capacity

Cloudflare Browser Run has a shared 10 browser-minute daily cap across all converters. The backend shows actual used minutes, allows one conversion at a time with cooldown, and stops before the shared budget is exhausted. yotomp3 advertises 10 conversions daily; EzConv advertises no daily cap, but availability is not guaranteed. Provider quota remaining is not exposed. Chaining providers does not remove the shared Cloudflare limit. Failures never invent analysis. Saved songs remain available when new analysis is limited.

### Source and license

This project is licensed under AGPL-3.0. See LICENSE and THIRD-PARTY-NOTICES.md. Browser analysis uses unmodified Essentia.js builds; upstream source and build instructions are at https://github.com/MTG/essentia.js . Backend source is in backend/. No persistent credentials are included. Deploy with Cloudflare Workers Free only; SQLite-backed Durable Objects manage atomic quotas.
