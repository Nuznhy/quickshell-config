.pragma library

var roles = ['bg', 'surface', 'overlay', 'muted', 'subtle', 'text', 'love', 'gold', 'rose', 'pine', 'foam', 'iris', 'highlightLow', 'highlightMed', 'highlightHigh'];
function valid(value) {
    return !!value && ['dark', 'light'].every(function(mode) {
        return !!value[mode] && roles.every(function(role) {
            return typeof value[mode][role] === 'string' && /^#[0-9a-fA-F]{6}$/.test(value[mode][role]);
        });
    });
}
