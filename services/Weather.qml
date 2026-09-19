pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtPositioning

import qs.modules.common

Singleton {
    id: root
    // 10 minute
    readonly property int fetchInterval: Config.options.bar.weather.fetchInterval * 60 * 1000
    readonly property string city: Config.options.bar.weather.city
    readonly property bool useUSCS: Config.options.bar.weather.useUSCS
    property bool gpsActive: Config.options.bar.weather.enableGPS

    onUseUSCSChanged: {
        root.getData();
    }
    onCityChanged: {
        root.getData();
    }

    property var location: ({
        valid: false,
        lat: 0,
        lon: 0
    })

    property var data: ({
        uv: 0,
        humidity: 0,
        sunrise: "--:--",
        sunset: "--:--",
        windDir: "N",
        wCode: "113",
        city: "",
        wind: 0,
        precip: 0,
        visib: 0,
        press: 0,
        temp: null,
        tempFeelsLike: null,
        tempValue: null,
        tempUnit: root.useUSCS ? "°F" : "°C",
        unitSystem: root.useUSCS ? "imperial" : "metric",
        units: root.useUSCS ? {
            temp: "°F",
            wind: "mph",
            precip: "in",
            visib: "m",
            press: "psi"
        } : {
            temp: "°C",
            wind: "km/h",
            precip: "mm",
            visib: "km",
            press: "hPa"
        },
        description: "",
        hourly: [],
        lastRefresh: "",
        lastRefreshTime: "",
    })

    function normalizeSunTime(value) {
        if (!value)
            return "--:--";
        const match = String(value).trim().match(/(\d+):(\d+)\s*(AM|PM)/i);
        if (!match)
            return String(value);
        let hour = Number(match[1]);
        const modifier = match[3].toUpperCase();
        if (modifier === "PM" && hour !== 12)
            hour += 12;
        if (modifier === "AM" && hour === 12)
            hour = 0;
        return hour.toString().padStart(2, "0") + ":" + match[2];
    }

    function formatForecastHour(date) {
        return date.getHours().toString().padStart(2, "0");
    }

    function hourlyForecast(data, currentTemperature) {
        const forecast = data?.forecast ?? [];
        const entries = [];

        for (const day of forecast) {
            for (const hour of day?.hourly ?? []) {
                const hourValue = Math.floor(Number(hour?.time ?? 0) / 100);
                const timestamp = new Date(`${day.date}T${hourValue.toString().padStart(2, "0")}:00:00`);
                entries.push({
                    timestamp: timestamp,
                    temp: Number(root.useUSCS ? hour?.tempF : hour?.tempC),
                    chanceOfRain: Number(hour?.chanceofrain ?? 0),
                    weatherCode: hour?.weatherCode ?? "113"
                });
            }
        }

        if (entries.length === 0)
            return [];

        const now = new Date();
        let nearestIndex = 0;
        let nearestDistance = Number.MAX_VALUE;
        for (let index = 0; index < entries.length; index++) {
            const distance = Math.abs(entries[index].timestamp.getTime() - now.getTime());
            if (distance < nearestDistance) {
                nearestDistance = distance;
                nearestIndex = index;
            }
        }

        return entries.slice(nearestIndex, nearestIndex + 6).map((entry, index) => ({
            temp: index === 0 ? currentTemperature : entry.temp,
            chanceOfRain: entry.chanceOfRain,
            weatherCode: entry.weatherCode,
            time: index === 0 ? "now" : root.formatForecastHour(new Date(now.getTime() + index * 3 * 60 * 60 * 1000))
        }));
    }

    function refineData(data) {
        let temp = {};
        temp.uv = Number(data?.current?.uvIndex || 0);
        temp.humidity = Number(data?.current?.humidity || 0);
        temp.sunrise = root.normalizeSunTime(data?.astronomy?.sunrise);
        temp.sunset = root.normalizeSunTime(data?.astronomy?.sunset);
        temp.windDir = data?.current?.winddir16Point || "N";
        temp.wCode = data?.current?.weatherCode || "113";
        temp.city = data?.location?.areaName?.[0]?.value || "City";
        temp.description = data?.current?.weatherDesc?.[0]?.value?.trim() || "Unknown";

        if (root.useUSCS) {
            temp.unitSystem = "imperial";
            temp.wind = Number(data?.current?.windspeedMiles || 0);
            temp.precip = Number(data?.current?.precipInches || 0);
            temp.visib = Number(data?.current?.visibilityMiles || 0);
            temp.press = Number(data?.current?.pressureInches || 0);
            temp.temp = Number(data?.current?.temp_F || 0);
            temp.tempFeelsLike = Number(data?.current?.FeelsLikeF || 0);
            temp.tempValue = temp.temp;
            temp.tempUnit = "°F";
            temp.units = {
                temp: "°F",
                wind: "mph",
                precip: "in",
                visib: "m",
                press: "psi"
            };
        } else {
            temp.unitSystem = "metric";
            temp.wind = Number(data?.current?.windspeedKmph || 0);
            temp.precip = Number(data?.current?.precipMM || 0);
            temp.visib = Number(data?.current?.visibility || 0);
            temp.press = Number(data?.current?.pressure || 0);
            temp.temp = Number(data?.current?.temp_C || 0);
            temp.tempFeelsLike = Number(data?.current?.FeelsLikeC || 0);
            temp.tempValue = temp.temp;
            temp.tempUnit = "°C";
            temp.units = {
                temp: "°C",
                wind: "km/h",
                precip: "mm",
                visib: "km",
                press: "hPa"
            };
        }
        temp.hourly = root.hourlyForecast(data, temp.temp);
        temp.lastRefresh = DateTime.time + " • " + DateTime.date;
        temp.lastRefreshTime = DateTime.time;
        root.data = temp;
    }

    function getData() {
        let command = "curl -s wttr.in";

        if (root.gpsActive && root.location.valid) {
            command += `/${root.location.lat},${root.location.lon}`;
        } else {
            command += `/${formatCityName(root.city)}`;
        }

        // format as json
        command += "?format=j1";
        command += " | ";
        command += "jq '{current: .current_condition[0], location: .nearest_area[0], astronomy: .weather[0].astronomy[0], forecast: [.weather[] | {date, hourly: [.hourly[] | {time, tempC, tempF, chanceofrain, weatherCode}]}]}'";
        fetcher.command[2] = command;
        fetcher.running = true;
    }

    function formatCityName(cityName) {
        return cityName.trim().split(/\s+/).join('+');
    }

    Component.onCompleted: {
        if (!root.gpsActive) return;
        console.info("[WeatherService] Starting the GPS service.");
        positionSource.start();
    }

    Process {
        id: fetcher
        command: ["bash", "-c", ""]
        stdout: StdioCollector {
            onStreamFinished: {
                if (text.length === 0)
                    return;
                try {
                    const parsedData = JSON.parse(text);
                    root.refineData(parsedData);
                    // console.info(`[ data: ${JSON.stringify(parsedData)}`);
                } catch (e) {
                    console.error(`[WeatherService] ${e.message}`);
                }
            }
        }
    }

    PositionSource {
        id: positionSource
        updateInterval: root.fetchInterval

        onPositionChanged: {
            // update the location if the given location is valid
            // if it fails getting the location, use the last valid location
            if (position.latitudeValid && position.longitudeValid) {
                root.location.lat = position.coordinate.latitude;
                root.location.lon = position.coordinate.longitude;
                root.location.valid = true;
                // console.info(`📍 Location: ${position.coordinate.latitude}, ${position.coordinate.longitude}`);
                root.getData();
                // if can't get initialized with valid location deactivate the GPS
            } else {
                root.gpsActive = root.location.valid ? true : false;
                console.error("[WeatherService] Failed to get the GPS location.");
            }
        }

        onValidityChanged: {
            if (!positionSource.valid) {
                positionSource.stop();
                root.location.valid = false;
                root.gpsActive = false;
                Quickshell.execDetached(["notify-send", "Weather Service", "Cannot find a GPS service. Using the fallback method instead.", "-a", "Shell"]);
                console.error("[WeatherService] Could not aquire a valid backend plugin.");
            }
        }
    }

    Timer {
        running: !root.gpsActive
        repeat: true
        interval: root.fetchInterval
        triggeredOnStart: !root.gpsActive
        onTriggered: root.getData()
    }
}
