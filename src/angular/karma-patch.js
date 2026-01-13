// Aggressive patch for Node 18+ compatibility with old libraries
// Patches multiple serialization paths to handle objects with .inspect() method
const util = require('util');

// Create a helper to extract value from objects with inspect method
function resolveInspect(obj) {
    if (obj && typeof obj === 'object' && typeof obj.inspect === 'function' && !obj[util.inspect.custom]) {
        try {
            const result = obj.inspect();
            console.log('[karma-patch] Resolved inspect:', result);
            return result;
        } catch (e) {
            console.log('[karma-patch] inspect() threw:', e.message);
        }
    }
    return obj;
}

// Patch util.inspect
const originalInspect = util.inspect;
util.inspect = function(obj, ...rest) {
    return originalInspect.call(this, resolveInspect(obj), ...rest);
};

// Patch util.format to handle %s and %o with inspect objects
const originalFormat = util.format;
util.format = function(format, ...args) {
    const processedArgs = args.map(resolveInspect);
    return originalFormat.call(this, format, ...processedArgs);
};

// Patch JSON.stringify to call inspect before stringifying
const originalStringify = JSON.stringify;
JSON.stringify = function(obj, ...rest) {
    return originalStringify.call(this, resolveInspect(obj), ...rest);
};

// Patch console methods
['log', 'error', 'warn', 'info', 'debug'].forEach(method => {
    const original = console[method];
    console[method] = function(...args) {
        const processedArgs = args.map(resolveInspect);
        return original.apply(console, processedArgs);
    };
});

console.log('[karma-patch] Patches applied successfully');
