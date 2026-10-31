import { AsyncLocalStorage } from "node:async_hooks";

// The real registry's handlers all await their initial requester lookup before
// any effect. Only that lookup is a proven authorization-only prelude. Consuming
// the marker synchronously prevents later/concurrent checks from claiming it.
const prelude = new AsyncLocalStorage<{ pending: boolean }>();
const beforeEffect = new WeakSet<Error>();

export function withAuthorizationPrelude<T>(handler: () => Promise<T>): Promise<T> {
  return prelude.run({ pending: true }, handler);
}

export function initialRequesterLookup(): (error: Error) => void {
  const state = prelude.getStore();
  const initial = state?.pending === true;
  if (state) state.pending = false;
  return error => { if (initial) beforeEffect.add(error); };
}

export function failedBeforeEffect(error: unknown): boolean {
  return error instanceof Error && beforeEffect.has(error);
}
