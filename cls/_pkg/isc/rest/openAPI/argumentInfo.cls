Class %pkg.isc.rest.openAPI.argumentInfo Extends %pkg.isc.rest.openAPI.resourceInfoStub
{

/// Class where this object came from (ie. its ActionInfo's SourceClass)
Property SourceClass As %String [ Internal ];

/// Name of this argument
Property Name As %String [ Internal ];

/// Where the argument will be included in the request
Property Source As %String [ Internal ];

/// Whether or not the argument is required
Property Required As %Boolean [ Internal ];

/// The schema for this argument
Property Schema As %pkg.isc.rest.openAPI.model.schemaOrReference [ Internal ];

}

