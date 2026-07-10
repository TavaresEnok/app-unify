const endpointContracts = [
  { method: 'POST', path: '/sync-clients', owner: 'proxy-sgp', access: 'internal-secret', decision: 'keep' },
  { method: 'POST', path: '/get-cached-clients', owner: 'proxy-sgp', access: 'internal-secret', decision: 'keep' },
  { method: 'POST', path: '/get-single-client', owner: 'proxy-sgp', access: 'internal-secret', decision: 'keep' },
  { method: 'POST', path: '/check-cpf', owner: 'api-service', access: 'public-login', decision: 'facade' },
  { method: 'POST', path: '/get-client-data-for-login', owner: 'proxy-sgp', access: 'compatibility', decision: 'keep-temporarily' },
  { method: 'POST', path: '/get-consumption-data', owner: 'api-service', access: 'firebase-token', decision: 'facade' },
  { method: 'POST', path: '/get-invoices', owner: 'api-service', access: 'firebase-token', decision: 'facade' },
  { method: 'POST', path: '/unlock-trust', owner: 'api-service', access: 'firebase-token', decision: 'facade' },
  { method: 'POST', path: '/diagnostic/onu-signal', owner: 'api-service', access: 'firebase-token', decision: 'facade' },
  { method: 'POST', path: '/diagnostic/onu-signal-base', owner: 'proxy-sgp', access: 'firebase-token', decision: 'keep-temporarily' },
  { method: 'POST', path: '/diagnostic/analyze', owner: 'proxy-sgp', access: 'firebase-token', decision: 'keep-temporarily' },
  { method: 'POST', path: '/cpe/wifi/list', owner: 'api-service', access: 'firebase-token', decision: 'facade' },
  { method: 'POST', path: '/cpe/wifi/update', owner: 'api-service', access: 'firebase-token', decision: 'facade' },
  { method: 'GET', path: '/health', owner: 'proxy-sgp', access: 'healthcheck', decision: 'keep' },
];

module.exports = { endpointContracts };
