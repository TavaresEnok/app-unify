function selectExpiredRuns(names, now = Date.now(), days = 30, minimum = 3) {
    const completed = new Set(names.filter(name => name.endsWith('/manifest.json')).map(name => name.split('/')[2]));
    const runs = [...new Set(names.map(name => name.split('/')[2]))]
        .filter(name => /^\d{8}T\d{6}Z-\d+$/.test(name)).sort().reverse();
    const protectedRuns = new Set(runs.filter(name => completed.has(name)).slice(0, minimum));
    return new Set(runs.filter(name => {
        const date = `${name.slice(0, 4)}-${name.slice(4, 6)}-${name.slice(6, 8)}T${name.slice(9, 11)}:${name.slice(11, 13)}:${name.slice(13, 15)}Z`;
        return !protectedRuns.has(name) && now - Date.parse(date) > days * 86400000;
    }));
}
module.exports = { selectExpiredRuns };
