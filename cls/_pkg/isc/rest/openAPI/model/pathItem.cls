Include %pkg.isc.rest.general

/// A representation of the OpenAPI Specification Path Item Object (see http://spec.openapis.org/oas/v3.0.3#pathItemObject)
Class %pkg.isc.rest.openAPI.model.pathItem Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @OpenAPI: Allows for an external definition of this path item. The referenced structure MUST be in the format of a Path Item Object. In case a Path Item Object field appears both in the defined object and the referenced object, the behavior is undefined.
Property Ref As %String(%JSONFIELDNAME = "$ref", MAXLEN = 2000);

/// @OpenAPI: An optional, string summary, intended to apply to all operations in this path.
Property Summary As %String(%JSONFIELDNAME = "summary", MAXLEN = 2000);

/// @OpenAPI: An optional, string description, intended to apply to all operations in this path. CommonMark syntax MAY be used for rich text representation.
Property Description As %String(%JSONFIELDNAME = "description", MAXLEN = 2000);

/// @OpenAPI: A definition of a GET operation on this path.
Property Get As %pkg.isc.rest.openAPI.model.operation(%JSONFIELDNAME = "get");

/// @OpenAPI: A definition of a PUT operation on this path.
Property Put As %pkg.isc.rest.openAPI.model.operation(%JSONFIELDNAME = "put");

/// @OpenAPI: A definition of a POST operation on this path.
Property Post As %pkg.isc.rest.openAPI.model.operation(%JSONFIELDNAME = "post");

/// @OpenAPI: A definition of a DELETE operation on this path.
Property Delete As %pkg.isc.rest.openAPI.model.operation(%JSONFIELDNAME = "delete");

/// @OpenAPI: A definition of a OPTIONS operation on this path.
Property Options As %pkg.isc.rest.openAPI.model.operation(%JSONFIELDNAME = "options");

/// @OpenAPI: A definition of a HEAD operation on this path.
Property Head As %pkg.isc.rest.openAPI.model.operation(%JSONFIELDNAME = "head");

/// @OpenAPI: A definition of a PATCH operation on this path.
Property Patch As %pkg.isc.rest.openAPI.model.operation(%JSONFIELDNAME = "patch");

/// @OpenAPI: A definition of a TRACE operation on this path.
Property Trace As %pkg.isc.rest.openAPI.model.operation(%JSONFIELDNAME = "trace");

/// @OpenAPI: An alternative server array to service all operations in this path.
Property Servers As list Of %pkg.isc.rest.openAPI.model.server(%JSONFIELDNAME = "servers");

/// @OpenAPI: A list of parameters that are applicable for all the operations described under this path. These parameters can be overridden at the operation level, but cannot be removed there. The list MUST NOT include duplicated parameters. A unique parameter is defined by a combination of a name and location. The list can use the Reference Object to link to parameters that are defined at the OpenAPI Object’s components/parameters.
Property Parameters As list Of %pkg.isc.rest.openAPI.model.parameterOrReference(%JSONFIELDNAME = "parameters");

/// Used to track the endpoint "type"
Property EndpointType As %String(%JSONINCLUDE = "none", VALUELIST = "|action|resource|other");

/// Used to track whether or not this is an instance endpoint
Property IsInstance As %Boolean(%JSONINCLUDE = "none");

/// Used to track the class(es) that caused this object to be generated
Property SourceClasses As list Of %String(%JSONINCLUDE = "none");

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set refValid = 1
	If ..Ref'="" {
		Set refValid = $ClassName(..ResolveReference(..Ref, fullSpecification)) = $ClassName($This)
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
	Do:'refValid ..OnFail(fullSpecification, debug, "Reference (" _ ..Ref _ ") is invalid or does not refer to a Path object", "Ref")
	Do:'uniqueParamsValid ..OnFail(fullSpecification, debug, "List contains duplicate parameters", "Parameters")
	Return refValid && uniqueParamsValid
}

Method RemoveUnreachableOperations(permissionsRegex, sourceClass)
{
	If ..IsInstance {
		Do ..CheckRemove(..Get, $$$OperationRead, sourceClass)
	} Else {
		Do ..CheckRemove(..Get, $$$OperationQuery, sourceClass)
	}
	Do ..CheckRemove(..Put, $$$OperationUpdate, sourceClass)
	Do ..CheckRemove(..Post, $$$OperationCreate, sourceClass)
	Do ..CheckRemove(..Delete, $$$OperationDelete, sourceClass)
	Do ..CheckRemove(..Options, "", sourceClass)
	Do ..CheckRemove(..Head, "", sourceClass)
	Do ..CheckRemove(..Patch, "", sourceClass)
	Do ..CheckRemove(..Trace, "", sourceClass)
	
	Set found = 0
	Set found = found || ($IsObject(..Get) && (..Get.SourceClasses.Find(sourceClass)'=""))
	Set found = found || ($IsObject(..Put) && (..Put.SourceClasses.Find(sourceClass)'=""))
	Set found = found || ($IsObject(..Post) && (..Post.SourceClasses.Find(sourceClass)'=""))
	Set found = found || ($IsObject(..Delete) && (..Delete.SourceClasses.Find(sourceClass)'=""))
	Set found = found || ($IsObject(..Options) && (..Options.SourceClasses.Find(sourceClass)'=""))
	Set found = found || ($IsObject(..Head) && (..Head.SourceClasses.Find(sourceClass)'=""))
	Set found = found || ($IsObject(..Patch) && (..Patch.SourceClasses.Find(sourceClass)'=""))
	Set found = found || ($IsObject(..Trace) && (..Trace.SourceClasses.Find(sourceClass)'=""))
	If 'found {
		Do ..SourceClasses.RemoveAt(..SourceClasses.Find(sourceClass))
	}
}

Method CheckRemove(pOperationObj As %pkg.isc.rest.openAPI.model.operation, pPermissionRegex As %String, pPermission As %String, pSourceClass As %Dictionary.CacheClassname) [ Internal, Private ]
{
	Set removeArg = (pPermissionRegex = "")
	If (pPermissionRegex '= "") {
		If (..EndpointType = "action") {
			Set removeArg = removeArg && '$Match($$$OperationAction(pOperationObj.ActionName), pPermissionRegex)
		} ElseIf ..EndpointType = "resource" {
			If pOperationObj.ActionName = "new" {
				Set removeArg = removeArg && '$Match($$$OperationRead, pPermissionRegex)
			} Else {
				Set removeArg = removeArg && ((pPermission = "") || '$Match(pPermission, pPermissionRegex))
			}
		}
	}
	Set removeArg = removeArg && $IsObject(pOperationObj)
	If ($IsObject(pOperationObj) && ((pPermissionRegex="") || (((..EndpointType = "action") && ('$Match($$$OperationAction(pOperationObj.ActionName), pPermissionRegex)) || ((..EndpointType="resource")&&((pOperationObj.ActionName="new")&&('$Match($$$OperationRead, pPermissionRegex)))))||((..EndpointType="resource")&&(pPermission=""||('$Match(pPermission, pPermissionRegex))))))) {
		Do pOperationObj.RemoveAllFromSource(pSourceClass, .keepSelf)
		If ('keepSelf) {
			Set pOperationObj = $$$NULLOREF
		}
	}
}

Method RemoveAllFromSource(className As %String, Output keepSelf As %Boolean)
{
	Set sourceID = ..SourceClasses.Find(className)
	If sourceID="" {
		Set keepSelf = 1
		Return
	}
	
	Do ..Get.RemoveAllFromSource(className, .keep)
	Set:'keep ..Get = ""
	Do ..Put.RemoveAllFromSource(className, .keep)
	Set:'keep ..Put = ""
	Do ..Post.RemoveAllFromSource(className, .keep)
	Set:'keep ..Post = ""
	Do ..Delete.RemoveAllFromSource(className, .keep)
	Set:'keep ..Delete = ""
	Do ..Options.RemoveAllFromSource(className, .keep)
	Set:'keep ..Options = ""
	Do ..Head.RemoveAllFromSource(className, .keep)
	Set:'keep ..Head = ""
	Do ..Patch.RemoveAllFromSource(className, .keep)
	Set:'keep ..Patch = ""
	Do ..Trace.RemoveAllFromSource(className, .keep)
	Set:'keep ..Trace = ""
	For i=1:1:..Parameters.Count() {
		Set parameter = ..Parameters.GetAt(i)
		Do parameter.RemoveAllFromSource(sourceClass, .keepSelf)
		If 'keepSelf {
			Do ..Parameters.RemoveAt(i)
			Set i = i - 1
		}
	}
	
	Do ..SourceClasses.RemoveAt(sourceID)
	Set keepSelf = ..SourceClasses.Count()
}

Storage Default
{
<Data name="PathItemDefaultData">
<Subscript>"PathItem"</Subscript>
<Value name="1">
<Value>Ref</Value>
</Value>
<Value name="2">
<Value>Summary</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
<Value name="4">
<Value>Get</Value>
</Value>
<Value name="5">
<Value>Put</Value>
</Value>
<Value name="6">
<Value>Post</Value>
</Value>
<Value name="7">
<Value>Delete</Value>
</Value>
<Value name="8">
<Value>Options</Value>
</Value>
<Value name="9">
<Value>Head</Value>
</Value>
<Value name="10">
<Value>Patch</Value>
</Value>
<Value name="11">
<Value>Trace</Value>
</Value>
<Value name="12">
<Value>Servers</Value>
</Value>
<Value name="13">
<Value>Parameters</Value>
</Value>
<Value name="14">
<Value>EndpointType</Value>
</Value>
<Value name="15">
<Value>IsInstance</Value>
</Value>
<Value name="16">
<Value>SourceClasses</Value>
</Value>
</Data>
<DefaultData>PathItemDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

