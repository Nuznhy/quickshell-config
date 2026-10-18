.pragma library

function roundedPath(ctx, width, height, corners) {
    const limit = Math.min(width, height) / 2;
    const r = corners.map(value => Math.max(0, Math.min(limit, value)));
    ctx.beginPath();
    ctx.moveTo(r[0], 0);
    ctx.lineTo(width - r[1], 0);
    ctx.arcTo(width, 0, width, r[1], r[1]);
    ctx.lineTo(width, height - r[3]);
    ctx.arcTo(width, height, width - r[3], height, r[3]);
    ctx.lineTo(r[2], height);
    ctx.arcTo(0, height, 0, height - r[2], r[2]);
    ctx.lineTo(0, r[0]);
    ctx.arcTo(0, 0, r[0], 0, r[0]);
    ctx.closePath();
}

function dropdownPath(ctx, width, height, stemWidth, stemHeight, alignment, radius) {
    const r = Math.max(0, Math.min(radius, width / 2, (height - stemHeight) / 2));
    const nr = Math.min(r, stemHeight);
    const sr = Math.min(r, stemWidth / 2, stemHeight);
    let center = width / 2;
    if (alignment === "left")
        center = stemWidth / 2 + 10;
    else if (alignment === "right")
        center = width - stemWidth / 2 - 10;
    const left = center - stemWidth / 2;
    const right = center + stemWidth / 2;
    ctx.beginPath();
    ctx.moveTo(left + sr, 0);
    ctx.lineTo(right - sr, 0);
    ctx.arcTo(right, 0, right, sr, sr);
    ctx.lineTo(right, stemHeight - nr);
    ctx.arcTo(right, stemHeight, right + nr, stemHeight, nr);
    ctx.lineTo(width - r, stemHeight);
    ctx.arcTo(width, stemHeight, width, stemHeight + r, r);
    ctx.lineTo(width, height - r);
    ctx.arcTo(width, height, width - r, height, r);
    ctx.lineTo(r, height);
    ctx.arcTo(0, height, 0, height - r, r);
    ctx.lineTo(0, stemHeight + r);
    ctx.arcTo(0, stemHeight, r, stemHeight, r);
    ctx.lineTo(left - nr, stemHeight);
    ctx.arcTo(left, stemHeight, left, stemHeight - nr, nr);
    ctx.lineTo(left, sr);
    ctx.arcTo(left, 0, left + sr, 0, sr);
    ctx.closePath();
}

function paint(ctx, width, height, base, edge, edgeWidth, opacity, horizontal, path, frameInset, contentTop) {
    ctx.reset();
    if (width <= 0 || height <= 0)
        return;
    path();
    ctx.save();
    ctx.clip();
    // Aero glass gets its hue from the chosen surface and the desktop behind it.
    const tint = base;
    const light = (base.r + base.g + base.b) / 3 > 0.6;
    const body = ctx.createLinearGradient(0, 0, horizontal ? width : 0, horizontal ? 0 : height);
    const upper = Qt.tint(tint, light ? "#10ffffff" : "#20ffffff");
    const lower = Qt.tint(tint, light ? "#0c000000" : "#18000000");
    body.addColorStop(0, Qt.rgba(upper.r, upper.g, upper.b, base.a * opacity));
    body.addColorStop(0.48, Qt.rgba(tint.r, tint.g, tint.b, base.a * opacity));
    body.addColorStop(1, Qt.rgba(lower.r, lower.g, lower.b, base.a * opacity));
    ctx.fillStyle = body;
    ctx.fillRect(0, 0, width, height);

    // Reflections are clipped to the glass silhouette, including popup stems.
    ctx.globalAlpha = base.a;
    if (horizontal) {
        ctx.translate(width, 0);
        ctx.rotate(Math.PI / 2);
    }
    const span = horizontal ? height : width;
    const depth = horizontal ? width : height;
    // Feathered reflections slope down to the right, as on the Aero frame.
    ctx.save();
    ctx.transform(1, 0, 0.8, 1, 0, 0);
    for (const band of [[-0.35, 0.18, 0.12], [-0.08, 0.09, 0.18], [0.18, 0.16, 0.14], [0.54, 0.22, 0.16], [0.86, 0.08, 0.1]]) {
        const start = span * band[0];
        const size = span * band[1];
        const strength = band[2] * (light ? 0.55 : 1);
        const reflection = ctx.createLinearGradient(start, 0, start + size, 0);
        reflection.addColorStop(0, "transparent");
        reflection.addColorStop(0.2, Qt.rgba(1, 1, 1, strength * 0.6));
        reflection.addColorStop(0.4, Qt.rgba(1, 1, 1, strength));
        reflection.addColorStop(0.75, Qt.rgba(1, 1, 1, strength * 0.6));
        reflection.addColorStop(1, "transparent");
        ctx.fillStyle = reflection;
        ctx.fillRect(start, 0, size, depth);
    }
    ctx.restore();
    const sheen = ctx.createLinearGradient(0, 0, 0, depth * 0.49);
    sheen.addColorStop(0, "transparent");
    sheen.addColorStop(1, Qt.rgba(1, 1, 1, light ? 0.08 : 0.16));
    ctx.fillStyle = sheen;
    ctx.fillRect(0, 0, span, depth * 0.49);
    ctx.restore();
    // Keep text and controls on a solid client area, inside the glass frame.
    const inset = Math.min(frameInset || 0, width / 2, (height - (contentTop || 0)) / 2);
    if (inset > 0) {
        ctx.save();
        ctx.translate(inset, inset + (contentTop || 0));
        roundedPath(ctx, width - inset * 2, height - inset * 2 - (contentTop || 0), [2, 2, 2, 2]);
        ctx.fillStyle = base;
        ctx.fill();
        ctx.strokeStyle = Qt.rgba(0, 0, 0, base.a * (light ? 0.16 : 0.3));
        ctx.lineWidth = 1;
        ctx.stroke();
        ctx.restore();
    }
    if (edgeWidth <= 0)
        return;
    ctx.save();
    path();
    ctx.clip();
    ctx.strokeStyle = Qt.rgba(1, 1, 1, base.a * (light ? 0.16 : 0.3));
    ctx.lineWidth = (edgeWidth + 1) * 2;
    ctx.stroke();
    ctx.strokeStyle = edge;
    ctx.lineWidth = edgeWidth * 2;
    ctx.stroke();
    ctx.restore();
}
