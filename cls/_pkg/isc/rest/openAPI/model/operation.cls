/// A representation of the OpenAPI Specification Operation Object (see http://spec.openapis.org/oas/v3.0.3#operationObject)
Class %pkg.isc.rest.openAPI.model.operation Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @OpenAPI: A list of tags for API documentation control. Tags can be used for logical grouping of operations by resources or any other qualifier.
Property Tags As list Of %String(%JSONFIELDNAME = "tags", MAXLEN = 2000);

/// @OpenAPI: A short summary of what the operation does.
Property Summary As %String(%JSONFIELDNAME = "summary", MAXLEN = 2000);

/// @OpenAPI: A verbose explanation of the operation behavior. CommonMark syntax MAY be used for rich text representation.
Property Description As %String(%JSONFIELDNAME = "description", MAXLEN = 2000);

/// @OpenAPI: Additional external documentation for this operation.
Property ExternalDocumentation As %pkg.isc.rest.openAPI.model.externalDocumentation(%JSONFIELDNAME = "externalDocs");

/// @OpenAPI: Unique string used to identify the operation. The id MUST be unique among all operations described in the API. The operationId value is case-sensitive. Tools and libraries MAY use the operationId to uniquely identify an operation, therefore, it is RECOMMENDED to follow common programming naming conventions.
Property OperationID As %String(%JSONFIELDNAME = "operationId", MAXLEN = 2000);

/// @OpenAPI: A list of parameters that are applicable for this operation. If a parameter is already defined at the Path Item, the new definition will override it but can never remove it. The list MUST NOT include duplicated parameters. A unique parameter is defined by a combination of a name and location. The list can use the Reference Object to link to parameters that are defined at the OpenAPI Object’s components/parameters.
Property Parameters As list Of %pkg.isc.rest.openAPI.model.parameterOrReference(%JSONFIELDNAME = "parameters");

/// @OpenAPI: The request body applicable for this operation. The requestBody is only supported in HTTP methods where the HTTP 1.1 specification RFC7231 has explicitly defined semantics for request bodies. In other cases where the HTTP spec is vague, requestBody SHALL be ignored by consumers.
Property RequestBody As %pkg.isc.rest.openAPI.model.requestBodyOrReference(%JSONFIELDNAME = "requestBody");

/// @OpenAPI: The list of possible responses as they are returned from executing this operation.
Property Responses As %pkg.isc.rest.openAPI.model.responses(%JSONFIELDNAME = "responses") [ Required ];

/// @OpenAPI: A map of possible out-of band callbacks related to the parent operation. The key is a unique identifier for the Callback Object. Each value in the map is a Callback Object that describes a request that may be initiated by the API provider and the expected responses.
Property Callbacks As array Of %pkg.isc.rest.openAPI.model.callbackOrReference(%JSONFIELDNAME = "callbacks");

/// @OpenAPI: Declares this operation to be deprecated. Consumers SHOULD refrain from usage of the declared operation. Default value is false.
Property Deprecated As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "deprecated");

/// @OpenAPI: A declaration of which security mechanisms can be used for this operation. The list of values includes alternative security requirement objects that can be used. Only one of the security requirement objects need to be satisfied to authorize a request. To make security optional, an empty security requirement ({}) can be included in the array. This definition overrides any declared top-level security. To remove a top-level security declaration, an empty array can be used.
Property Security As list Of %pkg.isc.rest.openAPI.model.securityRequirement(%JSONFIELDNAME = "security");

/// @OpenAPI: An alternative server array to service this operation. If an alternative server object is specified at the Path Item Object or Root level, it will be overridden by this value.
Property Servers As list Of %pkg.isc.rest.openAPI.model.server(%JSONFIELDNAME = "servers");

/// The action name for this endpoint (if any)
Property ActionName As %String(%JSONINCLUDE = "none");

/// Used to track the class(es) that caused this object to be generated
Property SourceClasses As list Of %String(%JSONINCLUDE = "none");

/// Used to track the ActionInfo used in this operation's creation
Property SourceActionInfo As %pkg.isc.rest.openAPI.actionInfo(%JSONINCLUDE = "none");

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set uniqueOperationIdValid = 1
	If ..OperationID '= "" {
		Set operations = ..GetAllFromSpec(fullSpecification, $ClassName($This))
		For i=1:1:operations.Count() {
			If operations.GetAt(i).OperationID = ..OperationID && (operations.GetAt(i) '= $This){
				Set uniqueOperationIdValid = 0
				Quit
			}
		}
	}
	Set uniqueParamsValid = 1
	Set checkedParams = ##class(%ArrayOfDataTypes).%New()
	If $IsObject(..Parameters) {
		For i=1:1:..Parameters.Count() {
			Set parameter = ..Parameters.GetAt(i)
			If ($IsObject(parameter) && parameter.IsReference()) {
				Set parameter = ..ResolveReference(parameter.Ref, fullSpecification)
			}
			Set paramIdentifier = $lb(parameter.Name,parameter.In)
			If checkedParams.IsDefined(paramIdentifier) {
				Set uniqueParamsValid = 0
				Quit
			}
			Do checkedParams.SetAt(1, paramIdentifier)
		}
	}
	Do:'uniqueOperationIdValid ..OnFail(fullSpecification, debug, "Value (" _ ..OperationID _ ") not unique in specification", "OperationID")
	Do:'uniqueParamsValid ..OnFail(fullSpecification, debug, "List contains duplicate parameters", "Parameters")
	Return uniqueOperationIdValid && uniqueParamsValid
}

Method RemoveAllFromSource(className As %String, Output keepSelf As %Boolean)
{
	Set sourceID = ..SourceClasses.Find(className)
	If sourceID="" {
		Set keepSelf = 1
		Return
	}
	
	For i=1:1:..Parameters.Count() {
		Quit:i>..Parameters.Count()
		Do ..Parameters.GetAt(i).RemoveAllFromSource(className, .keep)
		If 'keep {
			Do ..Parameters.RemoveAt(i)
			Set i = i-1
		}
	}
	
	If $IsObject(..RequestBody) {
		Do ..RequestBody.RemoveAllFromSource(className, .keep)
		Set:'keep ..RequestBody = ""
	}
	
	If $IsObject(..Responses) {
		Do ..Responses.RemoveAllFromSource(className, .keep)
		Set:'keep ..Responses = ""
	}
	
	Do ..SourceClasses.RemoveAt(sourceID)
	Set keepSelf = ..SourceClasses.Count()
}

Storage Default
{
<Data name="Callbacks">
<Attribute>Callbacks</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.operation.Callbacks"</Subscript>
</Data>
<Data name="OperationDefaultData">
<Subscript>"Operation"</Subscript>
<Value name="1">
<Value>Tags</Value>
</Value>
<Value name="2">
<Value>Summary</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>ExternalDocumentation</Value>
</Value>
<Value name="5">
<Value>OperationID</Value>
</Value>
<Value name="6">
<Value>Parameters</Value>
</Value>
<Value name="7">
<Value>RequestBody</Value>
</Value>
<Value name="8">
<Value>Responses</Value>
</Value>
<Value name="9">
<Value>Deprecated</Value>
</Value>
<Value name="10">
<Value>Security</Value>
</Value>
<Value name="11">
<Value>Servers</Value>
</Value>
<Value name="12">
<Value>ActionName</Value>
</Value>
<Value name="13">
<Value>SourceClasses</Value>
</Value>
<Value name="14">
<Value>SourceActionInfo</Value>
</Value>
</Data>
<DefaultData>OperationDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

