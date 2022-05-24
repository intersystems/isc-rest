/// This class is internal to %pkg.isc.rest; consumers should not use or reference it directly.
Class %pkg.isc.rest.model.action.saSchema Extends %pkg.isc.json.util.saSchemaClass
{

/// This is the namespace value used to identify this SA schema.
/// This corresponds to the XMLNamespace keyword of a Studio XData block.
Parameter XMLNAMESPACE As STRING = "http://www.intersystems.com/_pkg/isc/rest/action";

/// This is comma-separated list of the classes whose xml elements
/// can be used as the root level element of a document.
Parameter ROOTCLASSES As STRING = "%pkg.isc.rest.model.action.t.actions:actions";

}
