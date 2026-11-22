# Third-party notices — Artemis PC 2026

Artemis PC 2026 is distributed under the GNU General Public License v3.0
(see `LICENSE`). It is built on top of Moonlight Qt and includes or links
against the following third-party components.

This file is a summary, not a replacement for the license texts. When
redistributing Artemis, keep the original license and notice files of each
component. The authoritative texts are available in the corresponding
upstream projects.

| Component | Version / artifact | License | Upstream |
|---|---|---|---|
| Moonlight Qt | 6.2.0 (base) | GPL-3.0 | https://github.com/moonlight-stream/moonlight-qt |
| moonlight-common-c | submodule `f900dd4` | GPL-3.0 | https://github.com/moonlight-stream/moonlight-common-c |
| qmdnsengine | submodule `920c097` | MIT | https://github.com/cgutman/qmdnsengine |
| h264bitstream | bundled | LGPL-2.1 | https://github.com/aizvorski/h264bitstream |
| SDL2 | 2.x (`SDL2.dll`, `SDL2_ttf.dll`) | zlib | https://github.com/libsdl-org/SDL |
| SDL3 / sdl2-compat | `SDL3.dll` | zlib | https://github.com/libsdl-org/SDL |
| SDL_GameControllerDB | submodule | zlib | https://github.com/gabomdq/SDL_GameControllerDB |
| Qt | 6.11.3 | LGPL-3.0 / GPL-3.0 / commercial | https://www.qt.io/licensing |
| FFmpeg | `avcodec-63`, `avutil-61`, `swscale-10` | LGPL-2.1-or-later (verify the exact build configuration) | https://ffmpeg.org/legal.html |
| libplacebo | `libplacebo-374.dll` | LGPL-2.1-or-later | https://github.com/haasn/libplacebo |
| OpenSSL | 3.x (`libcrypto-3-x64.dll`, `libssl-3-x64.dll`) | Apache-2.0 | https://www.openssl.org/source/license.html |
| Opus | `opus.dll` | BSD-3-Clause | https://opus-codec.org/license/ |
| dav1d | `dav1d.dll` | BSD-2-Clause | https://code.videolan.org/videolan/dav1d |
| Discord RPC | `discord-rpc.dll` | MIT | https://github.com/discord/discord-rpc |
| Microsoft Detours | `detours.lib` / AntiHooking | MIT | https://github.com/microsoft/Detours |
| AntiHooking | bundled DLL | GPL-3.0 (project code) + MIT (Microsoft Detours) | https://github.com/moonlight-stream/moonlight-qt |
| ModeSeven font | `ModeSeven.ttf` | See the font metadata/license in the source tree | — |

## Notes for redistributors

- Qt and libplacebo are used under LGPL-3.0/LGPL-2.1-or-later respectively.
  If you modify those libraries, you must comply with the LGPL requirements,
  including allowing replacement/relinking.
- FFmpeg's license depends on the build configuration. The binaries shipped
  with Artemis come from the `moonlight-qt-deps` release used by the project;
  verify that build's `--enable-gpl`/`--enable-nonfree` flags before
  redistributing under a different license.
- The full text of the GNU GPL v3.0 is included in `LICENSE` and in the
  installer's license page.

## Source code

Artemis PC 2026 source code and the corresponding source for the GPL-covered
components are available at:

- https://github.com/leonidas10009/Artemis-pc
- https://github.com/moonlight-stream/moonlight-qt
- https://github.com/moonlight-stream/moonlight-common-c

If you received a binary without the corresponding source, contact the
project through the repository's issue tracker.
