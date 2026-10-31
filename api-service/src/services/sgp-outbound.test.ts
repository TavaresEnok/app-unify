import { it } from "vitest";
import runtime from "./sgp-outbound";
const { scenarios } = require("../../../shared/runtime/sgp-outbound.scenarios");
for (const [name, scenario] of Object.entries(scenarios(runtime))) it(name, scenario as () => Promise<void>);
