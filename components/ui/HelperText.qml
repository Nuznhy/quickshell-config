import qs.components.ui as UI
import qs.config

UI.Text {
    property bool invalid: false
    role: "caption"
    color: invalid ? Design.danger : Design.textSecondary
    wrapMode: Text.WordWrap
}
