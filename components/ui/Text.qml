import QtQuick as Quick
import "../../config"

Quick.Text {
    property string role: "body"
    color: Design.text
    font.family: Design.fontFamily
    font.pixelSize: Design.textSize(role)
    font.weight: Design.heading(role) ? Quick.Font.DemiBold : Quick.Font.Normal
    lineHeight: role === "bar" ? 1 : Design.heading(role) ? Design.headingLineHeight : Design.bodyLineHeight
    textFormat: Quick.Text.PlainText
}
