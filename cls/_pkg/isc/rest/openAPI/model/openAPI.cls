/// A representation of the OpenAPI Specification OpenAPI Object (see http://spec.openapis.org/oas/v3.0.3#oasObject)
/// Note that this is the top-level object for a given OpenAPI Specification.
/// This class' Validate() method may be used to validate an entire specification.
Class %pkg.isc.rest.openAPI.model.openAPI Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// We have at most one openAPI spec per dispatch class at a time
Property DispatchClass As %Dictionary.CacheClassname(%JSONINCLUDE = "none");

Index DispatchClass On DispatchClass [ Unique ];

/// @OpenAPI: This string MUST be the semantic version number of the OpenAPI Specification version that the OpenAPI document uses. The openapi field SHOULD be used by tooling specifications and clients to interpret the OpenAPI document. This is not related to the API info.version string.
/// This value is initially taken from %pkg.isc.rest.openAPI, and should NOT be hardcoded here.
Property OpenAPI As %String(%JSONFIELDNAME = "openapi", MAXLEN = 2000) [ InitialExpression = {##class(%pkg.isc.rest.openAPI).#OpenAPIVersion}, Required ];

/// @OpenAPI: Provides metadata about the API. The metadata MAY be used by tooling as required.
Property Info As %pkg.isc.rest.openAPI.model.info(%JSONFIELDNAME = "info") [ Required ];

/// @OpenAPI: An array of Server Objects, which provide connectivity information to a target server. If the servers property is not provided, or is an empty array, the default value would be a Server Object with a url value of /.
Property Servers As list Of %pkg.isc.rest.openAPI.model.server(%JSONFIELDNAME = "servers");

/// @OpenAPI: The available paths and operations for the API.
Property Paths As %pkg.isc.rest.openAPI.model.paths(%JSONFIELDNAME = "paths") [ Required ];

/// @OpenAPI: An element to hold various schemas for the specification.
Property Components As %pkg.isc.rest.openAPI.model.components(%JSONFIELDNAME = "components");

/// @OpenAPI: A declaration of which security mechanisms can be used across the API. The list of values includes alternative security requirement objects that can be used. Only one of the security requirement objects need to be satisfied to authorize a request. Individual operations can override this definition. To make security optional, an empty security requirement ({}) can be included in the array.
Property Security As list Of %pkg.isc.rest.openAPI.model.securityRequirement(%JSONFIELDNAME = "security");

/// @OpenAPI: A list of tags used by the specification with additional metadata. The order of the tags can be used to reflect on their order by the parsing tools. Not all tags that are used by the Operation Object must be declared. The tags that are not declared MAY be organized randomly or based on the tools’ logic. Each tag name in the list MUST be unique.
Property Tags As list Of %pkg.isc.rest.openAPI.model.tag(%JSONFIELDNAME = "tags");

/// @OpenAPI: Additional external documentation.
Property ExternalDocs As %pkg.isc.rest.openAPI.model.externalDocumentation(%JSONFIELDNAME = "externalDocs");

/// Allows access to warnings found during the specification generation process (set before the spec is returned to the user, NOT updated in real-time)
Property Warnings As list Of %String(%JSONINCLUDE = "none", MAXLEN = 2000) [ Internal ];

/// Allows access to errors found during the specification generation process (NOT updated in real-time, see the note on ..Warnings)
Property Errors As list Of %String(%JSONINCLUDE = "none", MAXLEN = 2000) [ Internal ];

/// @Override: Validate the OpenAPI specification represented by this object
/// Note: Adds an additional optional gen parameter, defaulting to true, to control whether or not Reference Keys need to be (re)generated
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0, gen = 1) As %Boolean
{
	// Note: Including the %ValidateObject() and ValidateComponents() calls becuase this is taking the place of ValidateComponent()
	If debug {
		For i=1:1:..Warnings.Count() {
			Write *27,"[59mREST API Generation Warning:",*27,"[0m " _ ..Warnings.GetAt(i),!
		}
		For i=1:1:..Errors.Count() {
			Write *27,"[62mREST API Generation Error:",*27,"[0m " _ ..Errors.GetAt(i),!
		}
	}
	Do:gen ..GenerateRefKeys()
	Set objectValid = ..%ValidateObject()
	Set versionValid = $Match(..OpenAPI, ##class(%pkg.isc.rest.openAPI.util).#SEMVERREGEX)
	Set componentsValid = ..ValidateComponents($This, debug)
	If debug {
		Write:'objectValid "Object validation failed for " _ $This, !
		Write:'objectValid $System.Status.GetErrorText(objectValid), !
	}
	Do:'versionValid ..OnFail($This, debug, "SemVer (" _ ..OpenAPI _ ") Regex mismatch", "OpenAPI")
	Return objectValid && versionValid && componentsValid && '..Errors.Count()
}

/// @Override: Component-level validation on this object will always fail, as it should never be used as a component in a specification
Method ValidateComponent(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI, debug = 0) As %Boolean
{
	Return 0
}

/// Remove unused schemas from the specification
Method TrimSchemas(gen = 1)
{
	// Generate Reference Keys if not explicitly disabled (to be safe)
	Do:gen ..GenerateRefKeys()
	
	// Get a list of all references in the specification
	Set references = ..GetAllFromSpec($This, "%pkg.isc.rest.openAPI.model.reference")
	#Dim references As %ListOfObjects
	
	// Generate schema dependency lookup
	Set reflookups = ##class(%ArrayOfObjects).%New()
	Set key="", schema = ..Components.Schemas.GetNext(.key)
	While key'="" {
		Set schemaRef = ..GetReference($This, schema)
		Do reflookups.SetAt(##class(%ListOfDataTypes).%New(), schema)
		For i=1:1:references.Count() {
			Set ref = references.GetAt(i)
			Do:$Match(ref.Ref,"\Q"_schemaRef_"\E(/.*)*") reflookups.GetAt(schema).Insert(..GetReference($This,ref))
		}
		Set schema = ..Components.Schemas.GetNext(.key)
	}
	
	// Remove schemas with no references pointing to them
	Set key="", schema = ..Components.Schemas.GetNext(.key)
	While key'="" {
		If 'reflookups.GetAt(schema).Count() {
			Do ..Components.Schemas.RemoveAt(key)
			Set key = ..Components.Schemas.GetNext("")
			// Handle removing its references from reflookup
			Set schemaRef = ..GetReference($This, schema)
			Set key2="", schema2 = ..Components.Schemas.GetNext(.key2)
			While key2'="" {
				For i=1:1:reflookups.GetAt(schema2).Count() {
					If $Match(reflookups.GetAt(schema2).GetAt(i), "\Q" _ schemaRef _ "\E(/.*)*") {
						Do reflookups.GetAt(schema2).RemoveAt(i)
						Set i = i - 1
					}
				}
				Set schema2 = ..Components.Schemas.GetNext(.key2)
			}
		}
		Set schema = ..Components.Schemas.GetNext(.key)
	}
}

Storage Default
{
<Data name="OpenAPIDefaultData">
<Subscript>"OpenAPI"</Subscript>
<Value name="1">
<Value>OpenAPI</Value>
</Value>
<Value name="2">
<Value>Info</Value>
</Value>
<Value name="3">
<Value>Servers</Value>
</Value>
<Value name="4">
<Value>Paths</Value>
</Value>
<Value name="5">
<Value>Components</Value>
</Value>
<Value name="6">
<Value>Security</Value>
</Value>
<Value name="7">
<Value>Tags</Value>
</Value>
<Value name="8">
<Value>ExternalDocs</Value>
</Value>
<Value name="9">
<Value>Warnings</Value>
</Value>
<Value name="10">
<Value>Errors</Value>
</Value>
<Value name="11">
<Value>DispatchClass</Value>
</Value>
</Data>
<DefaultData>OpenAPIDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

