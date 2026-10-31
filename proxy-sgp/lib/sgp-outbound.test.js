const { test } = require('node:test');
const { scenarios } = require('../../shared/runtime/sgp-outbound.scenarios');
for (const [name, scenario] of Object.entries(scenarios(require('./sgp-outbound')))) test(name, scenario);
