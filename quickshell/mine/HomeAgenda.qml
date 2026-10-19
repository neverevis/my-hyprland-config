// Aba "Agenda" do Inicio: calendario do mes, tarefas (Settings.homeTodo) e um pomodoro, com os mesmos componentes
// dos widgets da area de trabalho.
import QtQuick

Item {
    id: pg
    property var home
    HomeCard {
        id: cal
        width: parent.width * 0.5 - 5; height: parent.height
        DwCalendar { anchors.fill: parent; anchors.margins: 4; cols: 2; rows: 2; opts: ({ weekStart: 1 }) }
    }
    HomeCard {
        id: todo
        anchors { left: cal.right; leftMargin: 10; right: parent.right; top: parent.top }
        height: parent.height - timer.height - 10
        DwTodo { anchors.fill: parent; anchors.margins: 4; cols: 2; rows: 2; wid: "@home"; opts: ({ items: Settings.homeTodo }) }
    }
    HomeCard {
        id: timer
        anchors { left: cal.right; leftMargin: 10; right: parent.right; bottom: parent.bottom }
        height: 128
        DwTimer { anchors.fill: parent; anchors.margins: 4; cols: 2; rows: 1; wid: "@home"; opts: ({ mode: "pomodoro" }) }
    }
}
