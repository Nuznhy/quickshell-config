.pragma library

const kits = [
    {id: "default", name: "Default", description: "The original bar and controls."},
    {id: "minimal", name: "Minimal", description: "A starter kit with square corners and understated control surfaces."},
    {id: "rounded", name: "Rounded", description: "A starter kit with soft corners and rounded control surfaces."},
    {id: "windows7", name: "Windows 7 Aero", description: "Tinted glass, glossy controls, and fine bevels. Choose Windows 7 Aero under Colors for its native palette."},
    {id: "windowsxp", name: "Windows XP Luna", description: "Glossy bars, cream panels, and beveled controls. Choose Windows XP Luna under Colors for its native palette."}
];

function hasKit(id) { return kits.some(kit => kit.id === id); }
function normalize(id) { return hasKit(id) ? id : "default"; }
