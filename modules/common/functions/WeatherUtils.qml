pragma Singleton
import Quickshell

Singleton {
    id: root

    /**
     * Formats temperature with unit. E.g. "22°C" or "72°F".
     * Accepts either a number (with optional unit) or a Weather.data object.
     * @param {number|object} tempOrData
     * @param {string} [unit]
     * @returns {string}
     */
    function formatTemperature(tempOrData, unit = null) {
        let temp = tempOrData;
        let unitStr = unit;
        if (typeof tempOrData === "object" && tempOrData !== null) {
            temp = tempOrData.temp !== undefined && tempOrData.temp !== null ? tempOrData.temp : tempOrData.tempValue;
            unitStr = unit ?? tempOrData.tempUnit ?? (tempOrData.unitSystem === "imperial" ? "°F" : "°C");
        }
        if (temp === null || temp === undefined || isNaN(temp))
            return "--°";
        return `${Math.round(Number(temp))}${unitStr ?? "°C"}`;
    }

    /**
     * Formats temperature numeric value without unit. E.g. "22" or "--".
     * @param {number|object} tempOrData
     * @returns {string}
     */
    function formatTempValue(tempOrData) {
        let temp = tempOrData;
        if (typeof tempOrData === "object" && tempOrData !== null) {
            temp = tempOrData.temp !== undefined && tempOrData.temp !== null ? tempOrData.temp : tempOrData.tempValue;
        }
        if (temp === null || temp === undefined || isNaN(temp))
            return "--";
        return String(Math.round(Number(temp)));
    }

    /**
     * Formats feels-like temperature with degree symbol only. E.g. "22°" or "--".
     * @param {number|object} tempOrData
     * @returns {string}
     */
    function formatFeelsLike(tempOrData) {
        let temp = tempOrData;
        if (typeof tempOrData === "object" && tempOrData !== null) {
            temp = tempOrData.tempFeelsLike;
        }
        if (temp === null || temp === undefined || isNaN(temp))
            return "--";
        return `${Math.round(Number(temp))}°`;
    }

    /**
     * Formats wind speed with unit and optional direction. E.g. "15 km/h N" or "9 mph SW".
     * @param {number|object} windOrData
     * @param {string} [dir]
     * @param {string} [unitSystem]
     * @returns {string}
     */
    function formatWind(windOrData, dir = "", unitSystem = "metric") {
        let wind = windOrData;
        let direction = dir;
        let units = unitSystem;
        if (typeof windOrData === "object" && windOrData !== null) {
            wind = windOrData.wind;
            direction = windOrData.windDir ?? "";
            units = windOrData.unitSystem ?? (windOrData.units?.wind === "mph" ? "imperial" : "metric");
        }
        if (wind === null || wind === undefined || isNaN(wind))
            return "--";
        const unit = units === "imperial" ? "mph" : "km/h";
        const dirPart = direction ? ` ${direction}` : "";
        return `${Math.round(Number(wind))} ${unit}${dirPart}`;
    }

    /**
     * Formats humidity percentage. E.g. "65%" or "--%".
     * @param {number|object} humidityOrData
     * @returns {string}
     */
    function formatHumidity(humidityOrData) {
        let humidity = humidityOrData;
        if (typeof humidityOrData === "object" && humidityOrData !== null) {
            humidity = humidityOrData.humidity;
        }
        if (humidity === null || humidity === undefined || isNaN(humidity))
            return "--%";
        return `${Math.round(Number(humidity))}%`;
    }

    /**
     * Formats UV index. E.g. "UV 2" or "UV --".
     * @param {number|object} uvOrData
     * @returns {string}
     */
    function formatUV(uvOrData) {
        let uv = uvOrData;
        if (typeof uvOrData === "object" && uvOrData !== null) {
            uv = uvOrData.uv;
        }
        if (uv === null || uv === undefined || isNaN(uv))
            return "UV --";
        return `UV ${uv}`;
    }

    /**
     * Formats sunrise and sunset range. E.g. "06:23 → 19:45".
     * @param {object|string} dataOrSunrise
     * @param {string} [sunset]
     * @returns {string}
     */
    function formatSunTimes(dataOrSunrise, sunset = null) {
        let rise = dataOrSunrise;
        let set = sunset;
        if (typeof dataOrSunrise === "object" && dataOrSunrise !== null) {
            rise = dataOrSunrise.sunrise;
            set = dataOrSunrise.sunset;
        }
        return `${rise || "--:--"} → ${set || "--:--"}`;
    }
}
