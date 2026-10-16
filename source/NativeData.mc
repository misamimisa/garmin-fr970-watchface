import Toybox.Complications;
import Toybox.Lang;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.WatchUi;
import Toybox.Weather;

class NativeData {
    var altitudeText as Lang.String = "ALT – m";
    var sunText as Lang.String = "SUN --:--";
    var heartRateText as Lang.String = "–";
    var daylight as Lang.Boolean or Null = null;

    var altitudeId = new Complications.Id(
        Complications.COMPLICATION_TYPE_ALTITUDE
    );
    var sunriseId = new Complications.Id(
        Complications.COMPLICATION_TYPE_SUNRISE
    );
    var sunsetId = new Complications.Id(
        Complications.COMPLICATION_TYPE_SUNSET
    );
    var heartRateId = new Complications.Id(
        Complications.COMPLICATION_TYPE_HEART_RATE
    );

    function start() as Void {
        Complications.registerComplicationChangeCallback(
            method(:onComplicationChanged)
        );

        subscribe(altitudeId);
        subscribe(sunriseId);
        subscribe(sunsetId);
        subscribe(heartRateId);

        refreshAltitude();
        refreshSun();
        refreshHeartRate();
    }

    function subscribe(id as Complications.Id) as Void {
        try {
            Complications.subscribeToUpdates(id);
        } catch (e) {
            // A system complication may be temporarily unavailable.
        }
    }

    function refreshAltitude() as Void {
        altitudeText = "ALT – m";

        try {
            var value = Complications.getComplication(altitudeId).value;
            if (value instanceof Lang.Float) {
                altitudeText = "ALT " + value.format("%.0f") + " m";
            }
        } catch (e) {
            // Keep the placeholder until altitude becomes available.
        }
    }

    function refreshHeartRate() as Void {
        heartRateText = "–";

        try {
            var value = Complications.getComplication(heartRateId).value;
            if (value instanceof Lang.Number && value > 0) {
                heartRateText = value.toString();
            }
        } catch (e) {
            // Keep the placeholder until heart rate becomes available.
        }
    }

    function readSeconds(id as Complications.Id) as Lang.Number or Null {
        try {
            var value = Complications.getComplication(id).value;
            if (value instanceof Lang.Number) {
                return value;
            }
        } catch (e) {
            // Keep the placeholder until the complication becomes available.
        }
        return null;
    }

    function formatSeconds(seconds as Lang.Number) as Lang.String {
        var hours = (seconds / 3600).toNumber();
        var minutes = ((seconds % 3600) / 60).toNumber();
        return hours.format("%02d") + ":" + minutes.format("%02d");
    }

    function tomorrowSunrise() as Lang.String {
        var weather = Weather.getCurrentConditions();
        if (weather == null ||
            weather.observationLocationPosition == null) {
            return "--:--";
        }

        var tomorrow = Time.now().add(new Time.Duration(86400));
        var sunrise = Weather.getSunrise(
            weather.observationLocationPosition,
            tomorrow
        );
        if (sunrise == null) {
            return "--:--";
        }

        var local = Gregorian.info(sunrise, Time.FORMAT_SHORT);
        return local.hour.format("%02d") + ":" + local.min.format("%02d");
    }

    function refreshSun() as Void {
        var sunrise = readSeconds(sunriseId);
        var sunset = readSeconds(sunsetId);
        var clock = System.getClockTime();
        var nowSeconds = clock.hour * 3600 + clock.min * 60;
        daylight = null;

        if (sunrise == null || sunset == null ||
            sunrise < 0 || sunset > 86399 ||
            sunrise >= sunset) {
            sunText = "SUN --:--";
            return;
        }

        daylight = nowSeconds >= sunrise && nowSeconds < sunset;

        if (nowSeconds < sunrise) {
            sunText = "RISE " + formatSeconds(sunrise);
        } else if (nowSeconds < sunset) {
            sunText = "SET " + formatSeconds(sunset);
        } else {
            sunText = "RISE " + tomorrowSunrise();
        }
    }

    function onComplicationChanged(id as Complications.Id) as Void {
        if (id.equals(altitudeId)) {
            refreshAltitude();
        } else if (id.equals(heartRateId)) {
            refreshHeartRate();
        } else if (id.equals(sunriseId) || id.equals(sunsetId)) {
            refreshSun();
        }

        WatchUi.requestUpdate();
    }

    function stop() as Void {
        Complications.unsubscribeFromAllUpdates();
        Complications.registerComplicationChangeCallback(null);
    }
}
