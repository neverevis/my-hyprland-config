// Icones (Material Design Icons da Nerd Font). Uso: Ico.g("home") ou o componente UiIcon com name: "home".
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property string family: "JetBrainsMono Nerd Font Propo"
    readonly property var map: ({
        home: 0xF02DC, music: 0xF075A, volume: 0xF057E, volumeMed: 0xF0580, volumeLow: 0xF057F, volumeOff: 0xF0581,
        mic: 0xF036C, micOff: 0xF036D, monitor: 0xF0379, chip: 0xF061A, memory: 0xF035B, gpu: 0xF08AE,
        wifi: 0xF05A9, wifiOff: 0xF05AA, wifi1: 0xF091F, wifi2: 0xF0922, wifi3: 0xF0925, wifi4: 0xF0928, wifiLock: 0xF16BF,
        bluetooth: 0xF00AF, btOff: 0xF00B2, btConnect: 0xF00B1, bell: 0xF009A, bellOff: 0xF009B, bellSleep: 0xF00A0, bellCog: 0xF1A29,
        cog: 0xF0493, close: 0xF0156, power: 0xF0425, lan: 0xF0317, ethernet: 0xF0200, thermo: 0xF050F, disk: 0xF02CA,
        night: 0xF0594, sun: 0xF05A8, themeAuto: 0xF050E, leaf: 0xF032A, rocket: 0xF14DE, balance: 0xF05D1,
        play: 0xF040A, pause: 0xF03E4, next: 0xF04AD, prev: 0xF04AE, shuffle: 0xF049D, repeat: 0xF0456, repeatOff: 0xF0457,
        refresh: 0xF0450, check: 0xF012C, lock: 0xF033E, palette: 0xF03D8, image: 0xF02E9, images: 0xF02F9, apps: 0xF003B,
        dashboard: 0xF056E, tune: 0xF062E, blur: 0xF00B5, animation: 0xF05D8, speaker: 0xF04C3, headphones: 0xF02CB,
        account: 0xF0004, clock: 0xF0954, calendar: 0xF00ED, chart: 0xF012A, down: 0xF072E, up: 0xF0737,
        frame: 0xF0E5F, glass: 0xF05CC, grain: 0xF0D7C, wallpaper: 0xF0E09, carousel: 0xF056C, transition: 0xF0915,
        plus: 0xF0415, minus: 0xF0374, trash: 0xF01B4, pencil: 0xF03EB, restore: 0xF099B, info: 0xF02FC, broom: 0xF00E2,
        send: 0xF048A, flask: 0xF0093, arch: 0xF08C7, linux: 0xF033D, gauge: 0xF029A, speed: 0xF04C5, pulse: 0xF0430,
        dock: 0xF10AC, layers: 0xF0328, link: 0xF0337, chevRight: 0xF0142, chevLeft: 0xF0141, arrowUp: 0xF005D, arrowDown: 0xF0045,
        alignLeft: 0xF11C2, alignCenter: 0xF11C3, alignRight: 0xF11C4, rounded: 0xF0607, curve: 0xF0559, timer: 0xF051B,
        bars: 0xF06FC, cards: 0xF0638, fullscreen: 0xF0293, dice: 0xF01CE, folder: 0xF024F, magic: 0xF1844, auto: 0xF0068,
        arrow_right: 0xF0054, arrow_left: 0xF004D, arrow_bottom_right: 0xF0043, arrow_bottom_left: 0xF0042, arrow_top_left: 0xF005B, arrow_top_right: 0xF005C,
        brush: 0xF00E3, eye: 0xF0208, history: 0xF02DA, swap_horizontal: 0xF04E1, swap_vertical: 0xF04E2, view_column: 0xF056D, view_grid: 0xF0570, web: 0xF059F,
        mouse: 0xF037D, keyboard: 0xF030C, cellphone: 0xF011C, gamepad: 0xF0297,
        lightning: 0xF140B, sleep: 0xF0904, logout: 0xF0343, restart: 0xF0709, desktop: 0xF0AAB, router: 0xF0469, devices: 0xF0FB0,
        folderPlain: 0xF024B, folderImage: 0xF024F, folderHome: 0xF10B5, download: 0xF01DA, arrowLeft: 0xF004D, search: 0xF0349,
        sortName: 0xF05BD, sortTime: 0xF154B, folderOpen: 0xF0770, camera: 0xF0100, eyeOff: 0xF0209, arrowRight: 0xF0054, caps: 0xF030E, unlock: 0xF0FC6, accountEdit: 0xF06BC,
        wSun: 0xF0599, wNight: 0xF0594, wPartly: 0xF0595, wNightPartly: 0xF0F31, wCloudy: 0xF0590, wFog: 0xF0591, wRain: 0xF0597, wPour: 0xF0596,
        wSnow: 0xF0598, wStorm: 0xF0593, wWind: 0xF059D, wHail: 0xF0592, humidity: 0xF058E, sunrise: 0xF059C, sunset: 0xF059B, umbrella: 0xF054A, mapMarker: 0xF034E,
        stopwatch: 0xF051F, bellRing: 0xF009E, coffee: 0xF0176, target: 0xF04FE, textBox: 0xF09ED, flower: 0xF024A, disc: 0xF0025, quote: 0xF0757, earth: 0xF01E7,
        listCheck: 0xF0C51, checkbox: 0xF0135, checkboxEmpty: 0xF0131, gpuCard: 0xF08AE, network: 0xF06F3, temperature: 0xF050F, lockOpen: 0xF0FC6, menu: 0xF035C,
        calc: 0xF00EC, chevUp: 0xF0143, chevDown: 0xF0140, window: 0xF05B2, wave: 0xF095B, moon: 0xF0F65, sparkle: 0xF1545, tag: 0xF04F9, compose: 0xF0284,
        font: 0xF06D6, textSize: 0xF027F, bold: 0xF0264, italic: 0xF0277, swatch: 0xF08B5, shape: 0xF0831, ruler: 0xF046D, resize: 0xF0A68,
        rotate: 0xF0467, crop: 0xF019E, clockDigital: 0xF0E97, clockOutline: 0xF0150, calendarWeek: 0xF0A33, cloudSun: 0xF0595, noteText: 0xF039E,
        sticker: 0xF1364, textShadow: 0xF0669, lockClock: 0xF097F, sineWave: 0xF095B, equalizer: 0xF0EA2, counter: 0xF0199, grid: 0xF02C1,
        circleOutline: 0xF0766, squareRounded: 0xF14FC, hexagon: 0xF02D9, flowerOutline: 0xF09F0, cursorMove: 0xF01BE, fileImage: 0xF021F,
        eyedropper: 0xF020A, opacity: 0xF05CC, numeric: 0xF03A0, text: 0xF09A8, album: 0xF0025, accountCircle: 0xF0009, greeting: 0xF17C4,
        fileSwap: 0xF0FB4, imageEdit: 0xF11E3, dotsCircle: 0xF1978, progressCheck: 0xF0995, listChecks: 0xF0756, quoteClose: 0xF027E,
        chartDonut: 0xF07AF, alignVCenter: 0xF11C6, tap: 0xF0741, star4: 0xF0AE2, imageFrame: 0xF0E49, bringForward: 0xF003D, copy: 0xF018F,
        paint: 0xF027C, compass: 0xF018C, tuneVariant: 0xF1542, wave2: 0xF0F2E, emoticon: 0xF01F2
    })
    function g(name: string): string { const c = map[name]; return c ? String.fromCodePoint(c) : "" }
}
