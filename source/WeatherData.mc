import Toybox.Lang;
import Toybox.Time;
import Toybox.Weather;

class WeatherData {
    var temperatureText as Lang.String = "–°";
    var uvText as Lang.String = "–";
    var condition as Lang.Number or Null = null;

    function refresh() as Void {
        temperatureText = "–°";
        uvText = "–";
        condition = null;

        var current = Weather.getCurrentConditions();
        if (current == null || current.observationTime == null) {
            return;
        }

        // Не показываем будущие или устаревшие наблюдения.
        var age = Time.now().compare(current.observationTime);
        if (age < -300 || age > 10800) {
            return;
        }

        if (current.temperature != null) {
            temperatureText = current.temperature.toFloat().format("%.0f") + "°";
        }
        if (current.uvIndex != null) {
            uvText = current.uvIndex.format("%.0f");
        }
        condition = current.condition;
    }
}