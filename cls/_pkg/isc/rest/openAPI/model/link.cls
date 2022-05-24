/// A representation of the OpenAPI Specification Link Object (see http://spec.openapis.org/oas/v3.0.3#linkObject)
Class %pkg.isc.rest.openAPI.model.link Extends (%pkg.isc.rest.openAPI.model.linkOrReference, %pkg.isc.rest.openAPI.model.extensibleSuper)
{

/// @OpenAPI: A relative or absolute URI reference to an OAS operation. This field is mutually exclusive of the operationId field, and MUST point to an Operation Object. Relative operationRef values MAY be used to locate an existing Operation Object in the OpenAPI definition.
Property OperationRef As %String(%JSONFIELDNAME = "operationRef", MAXLEN = 2000);

/// @OpenAPI: The name of an existing, resolvable OAS operation, as defined with a unique operationId. This field is mutually exclusive of the operationRef field.
Property OperationID As %String(%JSONFIELDNAME = "operationId", MAXLEN = 2000);

/// @OpenAPI: A map representing parameters to pass to an operation as specified with operationId or identified via operationRef. The key is the parameter name to be used, whereas the value can be a constant or an expression to be evaluated and passed to the linked operation. The parameter name can be qualified using the parameter location [{in}.]{name} for operations that use the same parameter name in different locations (e.g. path.id).
Property Parameters As array Of %pkg.isc.rest.openAPI.model.genericObject(%JSONFIELDNAME = "parameters");

/// @OpenAPI: A literal value or {expression} to use as a request body when calling the target operation.
Property RequestBody As %pkg.isc.rest.openAPI.model.genericObject(%JSONFIELDNAME = "requestBody");

/// @OpenAPI: A description of the link. CommonMark syntax MAY be used for rich text representation.
Property Description As %String(%JSONFIELDNAME = "description", MAXLEN = 2000);

/// @OpenAPI: A server object to be used by the target operation.
Property Server As %pkg.isc.rest.openAPI.model.server(%JSONFIELDNAME = "server");

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set refValid = 1
	If ..OperationRef '= "" {
		Set ref = ..ResolveReference(..OperationRef)
		Set refValid = $IsObject(ref) && ($ClassName(ref) = "%pkg.isc.rest.openAPI.model.operation")
	}
	Set idValid = 1
	If ..OperationID '= "" {
		Set idValid = 0
		Set operations = ..GetAllFromSpec(fullSpecification, "%pkg.isc.rest.openAPI.model.operation")
		For i=1:1:operations.Count() {
			If operations.GetAt(i).OperationID = ..OperationID {
				Set idValid = 1
				Quit
			}
		}
	}
	Set exclusiveValid = (..OperationRef="") || (..OperationID="")
	Do:'refValid ..OnFail(fullSpecification, debug, "Reference (" _ ..OperationRef _ ") is invalid or does not point to an Operation object", "OperationRef")
	Do:'idValid ..OnFail(fullSpecification, debug, "OperationID (" _ ..OperationID _ ") pointer does not match any known IDs", "OperationID")
	Do:'exclusiveValid ..OnFail(fullSpecification, debug, "Only one of OperationRef/OperationID should be specified")
	Return refValid && idValid && exclusiveValid
}

Storage Default
{
<Data name="Extras">
<Attribute>Extras</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.link.Extras"</Subscript>
</Data>
<Data name="LinkDefaultData">
<Subscript>"Link"</Subscript>
<Value name="1">
<Value>OperationRef</Value>
</Value>
<Value name="2">
<Value>OperationID</Value>
</Value>
<Value name="3">
<Value>RequestBody</Value>
</Value>
<Value name="4">
<Value>Description</Value>
</Value>
<Value name="5">
<Value>Server</Value>
</Value>
<Value name="6">
<Value>ClassName</Value>
</Value>
<Value name="7">
<Value>Link</Value>
</Value>
<Value name="8">
<Value>Reference</Value>
</Value>
</Data>
<Data name="Parameters">
<Attribute>Parameters</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.link.Parameters"</Subscript>
</Data>
<DefaultData>LinkDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

