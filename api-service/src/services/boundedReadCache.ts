/** Bounded, process-local read cache. Shares in-flight reads; never stores errors. */
export class BoundedReadCache<T> {
  private readonly entries = new Map<string, { expires: number; value: Promise<T> }>();
  constructor(private readonly maxEntries: number, private readonly ttlMs: number) {}

  get(key: string, load: () => Promise<T>): Promise<T> {
    const existing = this.entries.get(key);
    if (existing && existing.expires > Date.now()) return existing.value;
    if (this.entries.size >= this.maxEntries) this.entries.delete(this.entries.keys().next().value!);
    const entry = { expires: Infinity, value: Promise.resolve().then(load) };
    this.entries.set(key, entry);
    void entry.value.then(() => { entry.expires = Date.now() + this.ttlMs; }, () => {
      if (this.entries.get(key) === entry) this.entries.delete(key);
    });
    return entry.value;
  }
  delete(key: string) { this.entries.delete(key); }
  clear() { this.entries.clear(); }
}
