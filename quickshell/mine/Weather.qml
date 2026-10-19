// Clima (Open-Meteo, sem chave): local pela cidade escolhida (geocoding) ou pelo IP; agora, proximas horas e 7 dias.
// So consulta enquanto alguem usa (widget/modulo chama Weather.use()); atualiza a cada Settings.weatherInterval minutos.
// IPC: qs -c mine ipc call weather refresh
pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property int users: 0
    function use() { users++; if (!ready && !busy) refresh() }
    function release() { users = Math.max(0, users - 1) }

    property bool ready: false
    property bool busy: false
    property string error: ""
    property string place: ""
    property real lat: 0
    property real lon: 0
    property var now: ({})       // { temp, feels, humidity, wind, code, day }
    property var hours: []       // [{ time: Date, temp, code, rain }]
    property var days: []        // [{ date: Date, max, min, code, rain, sunrise, sunset }]
    property date updated: new Date(0)
    readonly property bool imperial: Settings.weatherUnits === "imperial"
    readonly property string unit: imperial ? "°F" : "°C"
    readonly property string windUnit: imperial ? "mph" : "km/h"

    // codigo WMO -> descricao e icone (noite troca o sol pela lua)
    function describe(code) {
        const c = Number(code)
        if (c === 0) return "Céu limpo"
        if (c <= 2) return "Poucas nuvens"
        if (c === 3) return "Nublado"
        if (c <= 48) return "Neblina"
        if (c <= 57) return "Garoa"
        if (c <= 67) return "Chuva"
        if (c <= 77) return "Neve"
        if (c <= 82) return "Pancadas de chuva"
        if (c <= 86) return "Neve forte"
        return "Tempestade"
    }
    function icon(code, day) {
        const c = Number(code), d = day === undefined ? true : !!day
        if (c === 0) return d ? "wSun" : "wNight"
        if (c <= 2) return d ? "wPartly" : "wNightPartly"
        if (c === 3) return "wCloudy"
        if (c <= 48) return "wFog"
        if (c <= 57) return "wRain"
        if (c <= 67) return c >= 65 ? "wPour" : "wRain"
        if (c <= 77) return "wSnow"
        if (c <= 82) return "wPour"
        if (c <= 86) return "wSnow"
        return "wStorm"
    }

    function refresh() {
        busy = true; error = ""
        const city = Settings.weatherCity.trim()
        if (city !== "") { geo.command = ["curl", "-sf", "--max-time", "12", "https://geocoding-api.open-meteo.com/v1/search?count=1&language=pt&name=" + encodeURIComponent(city)]; geo.running = true }
        else { ip.running = true }
    }
    onImperialChanged: if (ready) fetch()
    Connections { target: Settings; function onWeatherCityChanged() { cityT.restart() } }
    Timer { id: cityT; interval: 1200; onTriggered: if (root.users > 0 || root.ready) root.refresh() }
    Timer { interval: Math.max(5, Settings.weatherInterval) * 60000; repeat: true; running: root.users > 0; onTriggered: root.refresh() }

    Process {
        id: ip
        command: ["curl", "-sf", "--max-time", "12", "http://ip-api.com/json/?fields=status,city,lat,lon"]
        stdout: StdioCollector { onStreamFinished: {
            try { const j = JSON.parse(text); if (j.status !== "success") throw 0; root.place = j.city; root.lat = j.lat; root.lon = j.lon; root.fetch() }
            catch (e) { root.busy = false; root.error = "Sem internet ou local desconhecido" }
        } }
    }
    Process {
        id: geo
        stdout: StdioCollector { onStreamFinished: {
            try { const r = JSON.parse(text).results[0]; root.place = r.name; root.lat = r.latitude; root.lon = r.longitude; root.fetch() }
            catch (e) { root.busy = false; root.error = "Cidade não encontrada: " + Settings.weatherCity }
        } }
    }
    function fetch() {
        const u = "https://api.open-meteo.com/v1/forecast?latitude=" + lat + "&longitude=" + lon
            + "&current=temperature_2m,apparent_temperature,relative_humidity_2m,weather_code,wind_speed_10m,is_day"
            + "&hourly=temperature_2m,weather_code,precipitation_probability,is_day&forecast_hours=24"
            + "&daily=weather_code,temperature_2m_max,temperature_2m_min,precipitation_probability_max,sunrise,sunset&forecast_days=7&timezone=auto"
            + (imperial ? "&temperature_unit=fahrenheit&wind_speed_unit=mph" : "")
        fc.command = ["curl", "-sf", "--max-time", "15", u]
        fc.running = true
    }
    Process {
        id: fc
        stdout: StdioCollector { onStreamFinished: {
            try {
                const j = JSON.parse(text), c = j.current
                root.now = { temp: c.temperature_2m, feels: c.apparent_temperature, humidity: c.relative_humidity_2m, wind: c.wind_speed_10m, code: c.weather_code, day: c.is_day === 1 }
                const h = j.hourly
                root.hours = h.time.map((t, i) => ({ time: new Date(t), temp: h.temperature_2m[i], code: h.weather_code[i], rain: h.precipitation_probability[i], day: h.is_day[i] === 1 }))
                const d = j.daily
                root.days = d.time.map((t, i) => ({ date: new Date(t + "T12:00"), max: d.temperature_2m_max[i], min: d.temperature_2m_min[i], code: d.weather_code[i],
                    rain: d.precipitation_probability_max[i], sunrise: new Date(d.sunrise[i]), sunset: new Date(d.sunset[i]) }))
                root.updated = new Date()
                root.ready = true
            } catch (e) { root.error = "Resposta inválida do serviço de clima" }
            root.busy = false
        } }
    }

    IpcHandler {
        target: "weather"
        function refresh(): void { root.refresh() }
        function status(): string { return JSON.stringify({ ready: root.ready, place: root.place, now: root.now, error: root.error }) }
    }
}
