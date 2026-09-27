.pragma library

function position(edge, buttonX, buttonY, buttonWidth, buttonHeight, windowWidth, windowHeight, popupWidth, popupHeight, alignment, stemWidth, showStem) {
    if (edge === "left") return {x: windowWidth + 4, y: buttonY + buttonHeight / 2 - popupHeight / 2};
    if (edge === "right") return {x: -popupWidth - 4, y: buttonY + buttonHeight / 2 - popupHeight / 2};
    let x = buttonX + buttonWidth / 2 - popupWidth / 2;
    if (alignment === "right") x = buttonX + buttonWidth / 2 - popupWidth + (showStem ? stemWidth / 2 + 10 : buttonWidth / 2 + 8);
    else if (alignment === "left") x = buttonX + buttonWidth / 2 - (showStem ? stemWidth / 2 + 10 : buttonWidth / 2 + 8);
    return {x: x, y: edge === "bottom" ? -popupHeight - 4 : showStem ? 32 : windowHeight + 4};
}
