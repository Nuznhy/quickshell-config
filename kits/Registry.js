.pragma library

const kits = [
    {id: "default", name: "Default", description: "The original bar and controls."},
    {id: "minimal", name: "Minimal", description: "A starter kit with square corners and understated control surfaces."},
    {id: "rounded", name: "Rounded", description: "A starter kit with soft corners and rounded control surfaces."}
];

function hasKit(id) { return kits.some(kit => kit.id === id); }
function normalize(id) { return hasKit(id) ? id : "default"; }
