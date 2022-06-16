/// Represents singleton settings object so implement only specific resource endpoints.
Class UnitTest.isc.rest.sample.model.settings Extends (%Persistent, %pkg.isc.rest.model.resource, %pkg.isc.json.adaptor, %pkg.isc.rest.model.iSerializable)
{

/// Name of the resource at the REST level
/// Subclasses MUST override this
Parameter RESOURCENAME As STRING = "settings";

Parameter SingletonID As STRING [ Internal ] = "singleton-settings";

/// %JSONFIELDNAMEASCAMELCASE auto-generates the %JSONFIELDNAME for properties (if not specified)
/// as camelCase.
Parameter %JSONFIELDNAMEASCAMELCASE As BOOLEAN = 1;

Property Timeout As %Integer [ InitialExpression = 90 ];

Property UnauthenticatedEnabled As %Boolean [ InitialExpression = 0 ];

Property SystemMode As %String [ InitialExpression = "Test" ];

Property InternalID As %String [ InitialExpression = {..#SingletonID}, ReadOnly, Required ];

Index InternalIDIdx On InternalID [ IdKey ];

/// Called by the handler when serving plural get requests. <br><br>
/// In the simplest case, the Resource is a Proxy and params are just query parameters for querying a table.
/// Note: This method should handle exporting JSON to the current device.
ClassMethod GetCollection(ByRef params, selectMode As %Integer)
{
	If '..%ExistsId(..#SingletonID) {
        Return
    }
    Set obj = ..%OpenId(..#SingletonID, , .sc)
    $$$ThrowOnError(sc)
    Set sc = obj.%JSONExport()
    $$$ThrowOnError(sc)
}

/// Returns an instance of this model, based on the arguments supplied.
ClassMethod GetModelInstance(args...) As UnitTest.isc.rest.sample.model.settings
{
    If '..%ExistsId(..#SingletonID) {
        Return ..%New()
    }
    Set obj = ..%OpenId(..#SingletonID, , .sc)
    $$$ThrowOnError(sc)
	Return obj
}

/// Saves the model instance.
Method SaveModelInstance(pUserContext As %RegisteredObject)
{
    Set sc = ..%Save()
    $$$ThrowOnError(sc)
}

/// Defines a mapping of actions available for this model class to the associated methods and arguments.
XData ActionMap [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/rest/action" ]
{
<actions>
<action name="expanded-user-info" method="GET" target="class" call="GetUserExpandedInfo">
<argument source="user-context" target="pUserContext" />
</action>
</actions>
}

ClassMethod GetUserExpandedInfo(pUserContext As UnitTest.isc.rest.sample.userContext) As %DynamicObject
{
	Quit {"UsernameUpper":($ZConvert(pUserContext.Username,"U"))}
}

/// Checks if the particular operation is supported for this resource. <br />
/// Look at documentation of <method>SupportsDefault</method> for default behavior
/// of this method. <br />
/// If the method returns 0, the corresponding dispatch class will return a 404
/// Not Found status when the operation is invoked. <br />
/// NOTE: This method runs on EVERY request so should be quick, lightweight checks
/// to prevent performance bottlenecks. <br />
/// <var>pOperation</var> may be one of the macros of the form $$$Operation*
/// present in %pkg.isc.rest.general.inc. <br />
/// <var>pType</var> is the type of the operation (instance-level on a particular
/// record or class-level). <br />
/// <var>pRequest</var> is the request object in an HTTP context.
/// NOTE: MUST check that this is an object before using it as it may be passed
/// as a NULL OREF in some cases. <br />
ClassMethod Supports(pOperation As %String, pType As %String(VALUELIST=",instance,class"), pRequest As %CSP.Request = {$$$NULLOREF}) As %Boolean
{
    // Only support GET and POST with no path or query parameters
    If (pType = "class") && ((pOperation = $$$OperationCreate) || (pOperation = $$$OperationQuery) || (pOperation = $$$OperationAction("expanded-user-info"))) {
        Return 1
    }
	Return 0
}

/// Checks the user's permission for a particular operation on a particular record.
/// <var>pOperation</var> may be one of the macros of the form $$$Operation*
/// present in %pkg.isc.rest.general.inc. <br />
/// If this method returns 0, the corresponding dispatch class will return a 403
/// Unauthorized status when the operation is invoked. <br />
/// <var>pUserContext</var> is supplied by <method>GetUserContext</method>. <br />
ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As %RegisteredObject, ByRef URLParams) As %Boolean
{
	// Just do same thing as Supports above
    Return ..Supports(pOperation, $Case(pID, "": "class", : "instance"))
}

/// JSONImport imports JSON or dynamic object input into this object.<br />
/// The input argument is either JSON as a string or stream, or a subclass of %DynamicAbstractObject.
Method JSONImport(input) As %Status
{
	Quit ..%JSONImport(.input)
}

/// Serialize a JSON enabled class as a JSON document and write it to the current device.
Method JSONExport() As %Status
{
	Quit ..%JSONExport()
}

/// Serialize a JSON enabled class as a JSON document and write it to a stream.
Method JSONExportToStream(ByRef export As %Stream.Object) As %Status
{
	Quit ..%JSONExportToStream(.export)
}

/// Serialize a JSON enabled class as a JSON document and return it as a string.
Method JSONExportToString(ByRef %export As %String) As %Status
{
	Quit ..%JSONExportToString(.%export)
}

Storage Default
{
<Data name="settingsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Timeout</Value>
</Value>
<Value name="3">
<Value>UnauthenticatedEnabled</Value>
</Value>
<Value name="4">
<Value>SystemMode</Value>
</Value>
</Data>
<DataLocation>^UnitTest.isc.rest71F2.settingsD</DataLocation>
<DefaultData>settingsDefaultData</DefaultData>
<IdLocation>^UnitTest.isc.rest71F2.settingsD</IdLocation>
<IndexLocation>^UnitTest.isc.rest71F2.settingsI</IndexLocation>
<StreamLocation>^UnitTest.isc.rest71F2.settingsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

