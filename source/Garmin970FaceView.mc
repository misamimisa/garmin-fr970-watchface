import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Weather;

class Garmin970FaceView extends WatchUi.WatchFace {

    var nativeData = new NativeData();
    var weatherData = new WeatherData();
    var lastSunMinute = -1;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    function onShow() as Void {
        nativeData.start();
    }

    function onUpdate(dc as Dc) as Void {
        // Use a 24-hour clock in both display modes.
        var clockTime = System.getClockTime();
        var timeString = Lang.format(
            "$1$:$2$",
            [clockTime.hour.format("%02d"), clockTime.min.format("%02d")]
        );

        // Keep the always-on display sparse and shift the time each minute.
        if (System.getDisplayMode() == System.DISPLAY_MODE_LOW_POWER) {
            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
            dc.clear();

            var aodFontHeight = dc.getFontHeight(Graphics.FONT_LARGE);
            var aodStep = aodFontHeight / 3 + 2;
            var aodTop = (
                dc.getHeight() - aodFontHeight - 3 * aodStep
            ) / 2;
            var aodY = aodTop + (clockTime.min % 4) * aodStep;

            dc.setColor(0x666666, Graphics.COLOR_BLACK);
            dc.drawText(
                dc.getWidth() / 2,
                aodY,
                Graphics.FONT_LARGE,
                timeString,
                Graphics.TEXT_JUSTIFY_CENTER
            );
            return;
        }

        // Update the time and date labels.
        var timeLabel = View.findDrawableById("TimeLabel") as Text;
        timeLabel.setText(timeString);

        var date = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
        var dateString = Lang.format(
            "$1$ $2$",
            [date.day_of_week.toString().toUpper(), date.day]
        );
        var dateLabel = View.findDrawableById("DateLabel") as Text;
        dateLabel.setText(dateString);

        // Update the battery level.
        var battery = System.getSystemStats().battery;
        var batteryLabel = View.findDrawableById("BatteryLabel") as Text;
        batteryLabel.setText(battery.format("%.0f"));

        // Refresh cached Garmin weather data.
        weatherData.refresh();

        var weatherLabel = View.findDrawableById("WeatherLabel") as Text;
        weatherLabel.setText(weatherData.temperatureText);

        var uvLabel = View.findDrawableById("UvLabel") as Text;
        uvLabel.setText(weatherData.uvText);

        // Update altitude and the next sun event.
        (View.findDrawableById("AltitudeLabel") as Text)
            .setText(nativeData.altitudeText);

        if (clockTime.min != lastSunMinute) {
            nativeData.refreshSun();
            lastSunMinute = clockTime.min;
        }

        (View.findDrawableById("SunEventLabel") as Text)
            .setText(nativeData.sunText);

        // Draw layout labels before the custom icons.
        View.onUpdate(dc);
        drawBattery(dc, battery);
        drawWeatherIcon(dc);
        drawHeartRate(dc);
    }

    function drawBattery(dc as Dc, battery as Lang.Float) as Void {
        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawRoundedRectangle(273, 102, 51, 25, 4);
        dc.fillRectangle(326, 109, 5, 11);

        var filled = ((battery + 24.0) / 25.0).toNumber();

        for (var i = 0; i < 4; i += 1) {
            if (i < filled) {
                dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
            } else {
                dc.setColor(Graphics.COLOR_DK_GRAY, Graphics.COLOR_BLACK);
            }
            dc.fillRectangle(278 + i * 11, 108, 8, 13);
        }
    }

    function drawWeatherIcon(dc as Dc) as Void {
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
        dc.drawText(
            272, 314,
            Graphics.FONT_SYSTEM_TINY,
            "UV",
            Graphics.TEXT_JUSTIFY_LEFT
        );

        var condition = weatherData.condition;
        if (condition == null || condition == Weather.CONDITION_UNKNOWN) {
            return;
        }

        if (condition == Weather.CONDITION_CLEAR ||
            condition == Weather.CONDITION_MOSTLY_CLEAR ||
            condition == Weather.CONDITION_PARTLY_CLEAR ||
            condition == Weather.CONDITION_FAIR) {
            if (nativeData.daylight == false) {
                drawMoon(dc, 91, 325);
            } else {
                drawSun(dc, 91, 325);
            }
        } else if (condition == Weather.CONDITION_PARTLY_CLOUDY ||
                   condition == Weather.CONDITION_THIN_CLOUDS) {
            if (nativeData.daylight == false) {
                drawMoon(dc, 83, 322);
            } else {
                drawSun(dc, 83, 322);
            }
            drawCloud(dc, 89, 340);
        } else {
            drawCloud(dc, 83, 340);
            if (condition == Weather.CONDITION_RAIN ||
                condition == Weather.CONDITION_LIGHT_RAIN ||
                condition == Weather.CONDITION_HEAVY_RAIN ||
                condition == Weather.CONDITION_DRIZZLE ||
                condition == Weather.CONDITION_SHOWERS ||
                condition == Weather.CONDITION_LIGHT_SHOWERS ||
                condition == Weather.CONDITION_HEAVY_SHOWERS ||
                condition == Weather.CONDITION_SCATTERED_SHOWERS ||
                condition == Weather.CONDITION_CHANCE_OF_SHOWERS ||
                condition == Weather.CONDITION_CLOUDY_CHANCE_OF_RAIN) {
                dc.drawLine(89, 351, 86, 357);
                dc.drawLine(101, 351, 98, 357);
            } else if (condition == Weather.CONDITION_SNOW ||
                       condition == Weather.CONDITION_LIGHT_SNOW ||
                       condition == Weather.CONDITION_HEAVY_SNOW ||
                       condition == Weather.CONDITION_FLURRIES ||
                       condition == Weather.CONDITION_CHANCE_OF_SNOW ||
                       condition == Weather.CONDITION_CLOUDY_CHANCE_OF_SNOW) {
                dc.fillCircle(88, 354, 2);
                dc.fillCircle(101, 354, 2);
            }
        }
    }

    function drawSun(dc as Dc, x as Lang.Number, y as Lang.Number) as Void {
        dc.drawCircle(x, y, 8);
        dc.drawLine(x, y - 16, x, y - 12);
        dc.drawLine(x, y + 12, x, y + 16);
        dc.drawLine(x - 16, y, x - 12, y);
        dc.drawLine(x + 12, y, x + 16, y);
        dc.drawLine(x - 11, y - 11, x - 8, y - 8);
        dc.drawLine(x + 8, y + 8, x + 11, y + 11);
        dc.drawLine(x - 11, y + 11, x - 8, y + 8);
        dc.drawLine(x + 8, y - 8, x + 11, y - 11);
    }

    function drawMoon(dc as Dc, x as Lang.Number, y as Lang.Number) as Void {
        dc.fillCircle(x, y, 10);
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_BLACK);
        dc.fillCircle(x + 6, y - 6, 9);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);
    }

    function drawCloud(dc as Dc, x as Lang.Number, y as Lang.Number) as Void {
        dc.fillCircle(x, y, 7);
        dc.fillCircle(x + 11, y - 6, 10);
        dc.fillCircle(x + 23, y, 7);
        dc.fillRectangle(x, y, 23, 8);
    }

    function drawHeartRate(dc as Dc) as Void {
        var value = nativeData.heartRateText;
        var font = Graphics.FONT_SYSTEM_SMALL;
        var heartWidth = 24;
        var gap = 9;
        var textWidth = dc.getTextWidthInPixels(value, font);
        var left = (dc.getWidth() - heartWidth - gap - textWidth) / 2;

        dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_BLACK);
        dc.fillCircle(left + 6, 49, 6);
        dc.fillCircle(left + 18, 49, 6);
        dc.fillPolygon([
            [left, 49],
            [left + 24, 49],
            [left + 12, 67]
        ]);

        dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_BLACK);
        dc.drawText(
            left + heartWidth + gap,
            30,
            font,
            value,
            Graphics.TEXT_JUSTIFY_LEFT
        );
    }

    function onHide() as Void {
        nativeData.stop();
    }

    function onExitSleep() as Void {
    }

    function onEnterSleep() as Void {
    }
}
