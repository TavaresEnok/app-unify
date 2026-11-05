const fs = require('fs');
const path = require('path');
class BuildJobStore {
    constructor(ttlMs = 24 * 60 * 60 * 1000, persistencePath) {
        this.ttlMs = ttlMs;
        this.persistencePath = persistencePath;
        this.jobs = new Map();
        if (persistencePath && fs.existsSync(persistencePath)) {
            // Não esconder corrupção: um estado inválido exige intervenção.
            const entries = JSON.parse(fs.readFileSync(persistencePath, 'utf8'));
            for (const [id, job] of entries) {
                if (Date.now() - (job.completedAt || job.createdAt) > ttlMs) continue;
                if (['preparing', 'running'].includes(job.status)) Object.assign(job, {
                    status: 'failed', completedAt: Date.now(), error: 'A geração foi interrompida por reinício do serviço. Gere novamente.',
                });
                this.jobs.set(id, job);
            }
            this.persist();
        }
    }
    persist() {
        if (!this.persistencePath) return;
        fs.mkdirSync(path.dirname(this.persistencePath), { recursive: true });
        const temp = `${this.persistencePath}.tmp`;
        fs.writeFileSync(temp, JSON.stringify([...this.jobs]), { mode: 0o600 });
        fs.renameSync(temp, this.persistencePath);
    }
    create(id, data) {
        const job = { id, status: 'preparing', createdAt: Date.now(), ...data };
        this.jobs.set(id, job); this.persist(); return job;
    }
    update(id, changes) {
        const job = this.get(id);
        if (!job) return null;
        Object.assign(job, changes); this.persist(); return job;
    }
    get(id) {
        const job = this.jobs.get(id);
        if (!job) return null;
        if (Date.now() - (job.completedAt || job.createdAt) > this.ttlMs) {
            this.jobs.delete(id); this.persist(); return null;
        }
        return job;
    }
}
module.exports = { BuildJobStore };
