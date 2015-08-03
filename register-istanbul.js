var coffeeCoverage = require('coffee-coverage');
var coverageVar = coffeeCoverage.findIstanbulVariable();
var writeOnExit = coverageVar == null ? true : null;

coffeeCoverage.register({
    instrumentor: 'istanbul',
    basePath: process.cwd(),
    exclude: ['/src/test', '/node_modules', '/.git'],
    coverageVar: coverageVar,
    writeOnExit: writeOnExit ? ((_ref = process.env.COFFEECOV_OUT) != null ? _ref : 'target/coverage/coverage-coffee.json') : null,
    initAll: (_ref = process.env.COFFEECOV_INIT_ALL) != null ? (_ref === 'true') : true
});
