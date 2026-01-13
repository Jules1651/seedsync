// Karma configuration file, see link for more information
// https://karma-runner.github.io/2.0/config/configuration-file.html

// Fix for Node 18+ compatibility with old libraries that use .inspect() method
// Node 18 no longer calls .inspect() methods automatically - must use Symbol
const util = require('util');

// Patch util.inspect to call old-style .inspect() methods
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

module.exports = function (config) {
    config.set({
        basePath: '',
        frameworks: ['jasmine', '@angular/cli'],
        plugins: [
            require('karma-jasmine'),
            require('karma-chrome-launcher'),
            require('karma-jasmine-html-reporter'),
            require('karma-coverage-istanbul-reporter'),
            require('@angular/cli/plugins/karma'),
            require('karma-mocha-reporter')
        ],
        client: {
            clearContext: false, // leave Jasmine Spec Runner output visible in browser
            captureConsole: false
        },
        coverageIstanbulReporter: {
            reports: ['html', 'lcovonly'],
            fixWebpackSourcePaths: true
        },
        angularCli: {
            environment: 'dev'
        },
        reporters: ['mocha', 'kjhtml'],
        port: 9876,
        colors: true,
        logLevel: config.LOG_DEBUG,
        autoWatch: true,
        browsers: ['Chrome'],
        singleRun: false,

        // Timeout settings for CI/Docker environments
        browserDisconnectTimeout: 10000,
        browserDisconnectTolerance: 3,
        browserNoActivityTimeout: 60000,
        captureTimeout: 60000,

        customLaunchers: {
            ChromeHeadless: {
                base: 'Chrome',
                flags: [
                    '--headless',
                    '--disable-gpu',
                    '--no-sandbox',
                    '--disable-dev-shm-usage',
                    '--remote-debugging-port=9222'
                ]
            }
        },
        mochaReporter: {
            output: 'full'
        }
    });
};
