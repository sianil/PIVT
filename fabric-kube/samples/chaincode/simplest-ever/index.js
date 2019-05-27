const shim = require('fabric-shim');
const Chaincode = require('./simplest-ever');

shim.start(new Chaincode());
