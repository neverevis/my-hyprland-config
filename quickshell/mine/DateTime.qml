// Formatos de hora e data do shell num lugar so (Configuracoes > Sessao > Hora e data).
// time(d) / date(d) / dateYear(d) / stamp(d) formatam; localize(fmt) troca o "HH:mm" de um formato livre pelo formato da hora escolhido.
pragma Singleton

import Quickshell
import QtQuick

Singleton {
    readonly property string suffix: Settings.clock24 ? "" : (Settings.clockAmPm === "ap" ? " ap" : " AP")
    readonly property string timeFmt: (Settings.clock24 ? "HH:mm" : "h:mm") + (Settings.clockSeconds ? ":ss" : "") + suffix
    readonly property string timeFmtSec: (Settings.clock24 ? "HH:mm" : "h:mm") + ":ss" + suffix
    function time(d: var, secs: bool): string { return Qt.formatDateTime(d, secs || Settings.clockSeconds ? timeFmtSec : timeFmt) }
    function date(d: var): string { return Qt.formatDateTime(d, Settings.dateFormat || "ddd, dd/MM") }
    function dateYear(d: var): string { return Qt.formatDateTime(d, Settings.dateYearFormat || "dd/MM/yyyy") }
    // data longa em pt-BR (o formato escolhido em Sessao, ou "def"); primeira letra maiuscula
    function long(d: var, def: var): string {
        const s = d.toLocaleDateString(Qt.locale("pt_BR"), Settings.dateLongFormat || def || "dddd, d 'de' MMMM")
        return s.charAt(0).toUpperCase() + s.slice(1)
    }
    function stamp(d: var): string { return date(d) + "   " + time(d) }
    // formato livre do usuario: o trecho "HH:mm" (a hora padrao) segue a escolha de 12/24 h e segundos
    function localize(fmt: string): string { return fmt.indexOf("HH:mm") >= 0 ? fmt.replace("HH:mm", timeFmt) : fmt }
    function formatted(d: var, fmt: string): string { return Qt.formatDateTime(d, fmt ? localize(fmt) : date(d) + "   " + timeFmt) }
}
