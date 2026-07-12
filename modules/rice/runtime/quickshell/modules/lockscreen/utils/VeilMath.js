.pragma library

function fract(value) {
    return value - Math.floor(value);
}

function hash(value) {
    return fract(Math.sin(value * 12.9898) * 43758.5453);
}

function mix(a, b, t) {
    return a + (b - a) * t;
}
