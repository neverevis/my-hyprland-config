// Componentes dos widgets da area de trabalho (tipo -> Component) e fontes manuscritas embutidas (assets/fonts, OFL).
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    id: root
    readonly property var handFonts: [caveat.name, dancing.name, vibes.name, indie.name, kalam.name, pacifico.name, patrick.name, marker.name].filter(n => n !== "")
    FontLoader { id: caveat; source: Qt.resolvedUrl("assets/fonts/Caveat.ttf") }
    FontLoader { id: dancing; source: Qt.resolvedUrl("assets/fonts/DancingScript.ttf") }
    FontLoader { id: vibes; source: Qt.resolvedUrl("assets/fonts/GreatVibes.ttf") }
    FontLoader { id: indie; source: Qt.resolvedUrl("assets/fonts/IndieFlower.ttf") }
    FontLoader { id: kalam; source: Qt.resolvedUrl("assets/fonts/Kalam.ttf") }
    FontLoader { id: pacifico; source: Qt.resolvedUrl("assets/fonts/Pacifico.ttf") }
    FontLoader { id: patrick; source: Qt.resolvedUrl("assets/fonts/PatrickHand.ttf") }
    FontLoader { id: marker; source: Qt.resolvedUrl("assets/fonts/PermanentMarker.ttf") }
    readonly property string script: caveat.name || "serif"

    property Component clock: Component { DwClock {} }
    property Component weather: Component { DwWeather {} }
    property Component world: Component { DwWorld {} }
    property Component calendar: Component { DwCalendar {} }
    property Component media: Component { DwMedia {} }
    property Component visualizer: Component { DwVisualizer {} }
    property Component system: Component { DwSystem {} }
    property Component user: Component { DwUser {} }
    property Component todo: Component { DwTodo {} }
    property Component notes: Component { DwNotes {} }
    property Component timer: Component { DwTimer {} }
    property Component text: Component { DwText {} }
    property Component image: Component { DwImage {} }
    property Component convert: Component { DwConvert {} }
    function component(type) { return root[type] instanceof Component ? root[type] : null }
}
