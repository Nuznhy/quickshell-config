import QtQuick
import "../../config"

Popup {
    // Options meet the frame without a padded gutter around the list.
    padding: Design.borderWidth
    background: MenuSurface { radius: 0 }
}
