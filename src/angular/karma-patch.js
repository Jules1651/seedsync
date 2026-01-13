// Aggressive patch for Node 18+ compatibility with old libraries
// Patches log4js directly since Karma uses it for logging
process.stderr.write('[karma-patch] Loading patch...\n');

const util = require('util');

// Helper to extract value from objects with inspect method
function resolveInspect(obj) {
    if (obj && typeof obj === 'object' && typeof obj.inspect === 'function') {
        try {
            const result = obj.inspect();
            process.stderr.write('[karma-patch] Resolved inspect: ' + result + '\n');
            return result;
        } catch (e) {
            process.stderr.write('[karma-patch] inspect() threw: ' + e.message + '\n');
            return e.message || String(obj);
        }
    }
    return obj;
}

// Patch util.inspect
const originalInspect = util.inspect;
util.inspect = function(obj, ...rest) {
    return originalInspect.call(this, resolveInspect(obj), ...rest);
};

// Patch util.format
const originalFormat = util.format;
util.format = function(format, ...args) {
    const processedArgs = args.map(resolveInspect);
    return originalFormat.call(this, format, ...processedArgs);
};

// Patch JSON.stringify with replacer to handle nested objects
const originalStringify = JSON.stringify;
JSON.stringify = function(obj, replacer, space) {
    const customReplacer = function(key, value) {
        const resolved = resolveInspect(value);
        if (replacer) {
            return typeof replacer === 'function' ? replacer(key, resolved) : resolved;
        }
        return resolved;
    };
    return originalStringify.call(this, obj, customReplacer, space);
};

// Patch console methods
['log', 'error', 'warn', 'info', 'debug'].forEach(method => {
    const original = console[method];
    console[method] = function(...args) {
        const processedArgs = args.map(resolveInspect);
        return original.apply(console, processedArgs);
    };
});

// Patch log4js if it's loaded
try {
    const log4js = require('log4js');
    const originalGetLogger = log4js.getLogger;
    log4js.getLogger = function(...args) {
        const logger = originalGetLogger.apply(this, args);
        ['trace', 'debug', 'info', 'warn', 'error', 'fatal'].forEach(level => {
            const originalMethod = logger[level].bind(logger);
            logger[level] = function(...logArgs) {
                const processedArgs = logArgs.map(resolveInspect);
                return originalMethod(...processedArgs);
            };
        });
        return logger;
    };
    process.stderr.write('[karma-patch] Patched log4js\n');
} catch (e) {
    process.stderr.write('[karma-patch] log4js not found, skipping patch\n');
}

process.stderr.write('[karma-patch] Patches applied successfully\n');
