/** @type {import('jest').Config} */
module.exports = {
  preset: "ts-jest",
  testEnvironment: "node",
  roots: ["<rootDir>/src"],
  testMatch: ["**/*.test.ts"],
  collectCoverageFrom: [
    "src/app/**/*.ts",
    "src/contracts/index.ts",
    "src/handlers/**/*.ts",
    "src/utils.ts",
    "!src/**/*.test.ts",
  ],
  coverageDirectory: "coverage",
  coverageThreshold: {
    global: {
      branches: 13,
      functions: 22,
      lines: 30,
      statements: 30,
    },
  },
};
