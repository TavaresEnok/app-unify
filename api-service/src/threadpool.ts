// Precisa rodar antes de qualquer uso do threadpool do libuv (dns.lookup,
// fs, crypto.scrypt). Consultas de DNS lentas não podem travar o resto.
if (!process.env.UV_THREADPOOL_SIZE) process.env.UV_THREADPOOL_SIZE = "16";
export {};
