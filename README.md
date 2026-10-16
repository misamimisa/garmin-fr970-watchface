# Garmin 970 Face

A personal Connect IQ watch face for the Garmin Forerunner 970. It uses a 24-hour clock and a minimal always-on display.

## Display

- Date, time and watch battery level
- Heart rate from Garmin's system complication (an en dash appears when unavailable)
- Current Garmin weather temperature, condition icon and UV index
- Altitude from a system complication
- Next sunrise or sunset; after sunset, tomorrow's sunrise is calculated for the weather observation location

In the always-on display, only a dim time is drawn. Its position changes slightly each minute.

Weather icons distinguish clear skies, partial cloud, cloud, rain and snow. Clear skies use a moon at night when sunrise and sunset data is available. Other conditions use the cloud icon. Weather readings older than three hours are hidden.

## Build

1. Install the [Garmin Connect IQ SDK](https://developer.garmin.com/connect-iq/overview/) and the Monkey C extension for VS Code.
2. Open this folder in VS Code and select **Forerunner 970** as the target device.
3. Use **Monkey C: Build for Simulator** to preview, or **Monkey C: Build for Device** to produce a `.prg` for the watch.
4. For a manual installation, copy the device build to `GARMIN/APPS` on the watch, then safely eject it.

The manifest requests `ComplicationSubscriber` for heart rate, altitude and sun events, and `Positioning` to access the weather observation location for tomorrow's sunrise. No API keys or network service are required; weather comes from Garmin's cached data.

## Notes

- Weather and complication values can temporarily be unavailable. The face shows placeholders instead of guessing.
- Sunrise and sunset complication values have differed in the simulator and on a physical FR970. Verify changes affecting sun events on the watch.
- The weather icon's night mode depends on valid sunrise and sunset complication values.
- This is a source project, not a Connect IQ Store release. Device builds and generated compiler files are excluded from the repository.
