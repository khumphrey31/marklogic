const util = require("/dmIde2dmf.sjs");
const dhfConfig = require("/com.marklogic.hub/config.sjs");

function normalizeInput(payload, params) {
 return (payload instanceof Sequence) ? payload.toArray()[0] : 
    (Array.isArray(payload) ? payload[0] : payload);
}

function errorHandler(statusCode, statusMsg, body) {
  fn.error(null, 'RESTAPI-SRVEXERR', Sequence.from([statusCode, statusMsg, body]));
}

function userError(msg) { errorHandler(400, "Input error", msg);}

function paramInput(params, attrib) {
  if (params[attrib] && params[attrib] != null) {
    var val = ("" + params[attrib]).trim();
    if (val.length > 0) return val;
  }
  userError("Missing required input: " + attrib);
}

function post(context, params, input) {

  input = xdmp.unquote(input); // IDE passes as string
  xdmp.log("dmfTestGibson params " + JSON.stringify(params));
  xdmp.log("dmfTestGibson input " + input);

  // collect input
  var entityName = paramInput(params, "entityName");
  var mappingName = paramInput(params, "mappingName");
  var sample = paramInput(params, "sample");
  var ninput = normalizeInput(input);

  xdmp.log("dmfTestGibson ninput type " + xdmp.type(ninput));
  xdmp.log("dmfTestGibson ninput " + JSON.stringify(ninput));

  context.outputTypes = ["application/json"];

  // obtain source
  var sourceURI = `/entities/${entityName}/harmonize/${mappingName}/samples/${sample}`;
  var source = fn.head(xdmp.eval('cts.doc(sourceURI)', {sourceURI: sourceURI}, {database: xdmp.database(dhfConfig.MODULESDATABASE)}));
  if (!source || source == null) userError("Sample not found *" + sourceURI + "*");

  // get DM mapping and run mapper
  var dmTemplate = util.convertDmIde2DMF4Test(ninput, entityName);
  var ret = {};
  ret[sample] = util.runDMMappingTest(dmTemplate, source);

  xdmp.log("dmfTestGibson ret " + JSON.stringify(ret));
  return xdmp.quote(ret); // IDE wants it back as string
}

exports.POST = post;