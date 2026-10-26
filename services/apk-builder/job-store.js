class BuildJobStore {
    constructor(ttlMs = 24 * 60 * 60 * 1000) {
        this.ttlMs = ttlMs;
        this.jobs = new Map();
    }

    create(id, data) {
        const job = {
            id,
            status: 'preparing',
            createdAt: Date.now(),
            ...data,
        };
        this.jobs.set(id, job);
        return job;
    }

    update(id, changes) {
        const job = this.get(id);
        if (!job) return null;
        Object.assign(job, changes);
        return job;
    }

    get(id) {
        const job = this.jobs.get(id);
        if (!job) return null;
        const referenceTime = job.completedAt || job.createdAt;
        if (Date.now() - referenceTime > this.ttlMs) {
            this.jobs.delete(id);
            return null;
        }
        return job;
    }
}

module.exports = { BuildJobStore };
