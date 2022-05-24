/// A representation of the OpenAPI Specification Server Variable Object (see http://spec.openapis.org/oas/v3.0.3#serverVariableObject)
Class %pkg.isc.rest.openAPI.model.serverVariable Extends %pkg.isc.rest.openAPI.model.extensibleSuper
{

/// @OpenAPI: An enumeration of string values to be used if the substitution options are from a limited set. The array SHOULD NOT be empty.
Property Enum As list Of %String(%JSONFIELDNAME = "enum", MAXLEN = 2000);

/// @OpenAPI: The default value to use for substitution, which SHALL be sent if an alternate value is not supplied. Note this behavior is different than the Schema Object’s treatment of default values, because in those cases parameter values are optional. If the enum is defined, the value SHOULD exist in the enum’s values.
Property Default As %String(%JSONFIELDNAME = "default", MAXLEN = 2000) [ Required ];

/// @OpenAPI: An optional description for the server variable. CommonMark syntax MAY be used for rich text representation.
Property Description As %String(%JSONFIELDNAME = "description", MAXLEN = 2000);

Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set enumValid = '$IsObject(..Enum) || (..Enum.Count() > 0)
	Set defaultValid = 1
	If $IsObject(..Enum) {
		Set defaultValid = 0
		For i=1:1:..Enum.Count() {
			If ..Enum.GetAt(i) = ..Default {
				Set defaultValid = 1
				Quit
			}
		}
	}
	Do:'enumValid ..OnFail(fullSpecification, debug, "Array cannot be empty", "Enum")
	Do:'defaultValid ..OnFail(fullSpecification, debug, "Default not found in Enum", "Default")
	Return enumValid && defaultValid
}

Storage Default
{
<Data name="ServerVariableDefaultData">
<Subscript>"ServerVariable"</Subscript>
<Value name="1">
<Value>Enum</Value>
</Value>
<Value name="2">
<Value>Default</Value>
</Value>
<Value name="3">
<Value>Description</Value>
</Value>
</Data>
<DefaultData>ServerVariableDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

