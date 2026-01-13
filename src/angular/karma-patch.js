// Patch util.inspect early, before Karma loads
// This fixes Node 18+ compatibility with old libraries that use .inspect() method
const util = require('util');

const originalInspect = util.inspect;
util.inspect = function(obj, options) {
    if (obj && typeof obj === 'object' && typeof obj.inspect === 'function' && !obj[util.inspect.custom]) {
        try {
            return obj.inspect();
        } catch (e) {
            // Fall through to original inspect
        }
    }
    return originalInspect.call(this, obj, options);
};

// Also patch console methods to handle objects with inspect
const originalConsoleError = console.error;
console.error = function(...args) {
    const processedArgs = args.map(arg => {
        if (arg && typeof arg === 'object' && typeof arg.inspect === 'function') {
            try {
                return arg.inspect();
            } catch (e) {
                return String(arg);
            }
        }
        return arg;
    });
    originalConsoleError.apply(console, processedArgs);
};
