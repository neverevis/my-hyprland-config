// Ajudas das pecas dos widgets (DwParts.qml): texto legivel em cima de uma cor e papel de cor -> papel do texto.
.pragma library

function inkOn(c) { return (0.299 * c.r + 0.587 * c.g + 0.114 * c.b) > 0.56 ? "#15131a" : "#f6f3fa" }
function inkRole(r) {
    return ({ primary: "onPrimary", secondary: "onSecondary", tertiary: "onTertiary", primaryContainer: "onPrimaryContainer",
              secondaryContainer: "onSecondaryContainer", tertiaryContainer: "onTertiaryContainer", error: "onError" })[r] || "text"
}
