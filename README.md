# RoundOS OTA files

Public **firmware files only**. Source stays private: [yzmilad/esp32-s3-touch-lcd-1.28](https://github.com/yzmilad/esp32-s3-touch-lcd-1.28).

The watch **never changes its URL**. It always downloads:

https://github.com/yzmilad/roundos-ota/releases/latest/download/version.json

## How later versions work

Do **not** type a new link on the watch.

1. Bump `OTA_FW_VERSION` in the firmware source (`ota_cfg.h`), e.g. `1.0.1`.
2. Build `firmware.bin`.
3. From this folder:

```powershell
.\publish.ps1 -Version 1.0.1 -Bin "C:\path\to\firmware.bin"
```

Every GitHub Release **must** attach both assets with these exact names:

| Asset | Role |
| --- | --- |
| `version.json` | `{"version":"1.0.1","url":"https://github.com/yzmilad/roundos-ota/releases/download/v1.0.1/firmware.bin"}` |
| `firmware.bin` | the image |

`/releases/latest/download/` follows the newest Release. If you rename those files, already-flashed watches 404.

First USB flash is still required (this `1.0.0` image). After that, Settings → Update → Check → Install.

Waveshare ESP32-S3-Touch-LCD-1.28, partition `16M Flash (3MB APP/9.9MB FATFS)`.
