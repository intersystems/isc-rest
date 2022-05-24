/// A representation of the OpenAPI Specification Schema Object (see http://spec.openapis.org/oas/v3.0.3#schemaObject)
/// For comments annotated with the @JSONSchemaValidation tag, information comes from the JSON Schema Validation document at https://tools.ietf.org/html/draft-wright-json-schema-validation-00, as specified in http://spec.openapis.org/oas/v3.0.3#schemaObject
Class %pkg.isc.rest.openAPI.model.schema Extends (%pkg.isc.rest.openAPI.model.schemaOrReference, %pkg.isc.rest.openAPI.model.extensibleSuper) [ SqlTableName = zSchema ]
{

/// @JSONSchemaValidation: [The title property] can be used to decorate a user interface with information about the data produced by this user interface [, and] will preferrably be short
Property Title As %String(%JSONFIELDNAME = "title", MAXLEN = 2000);

/// @JSONSchemaValidation: A numeric instance is only valid if division by this keyword's value results in an integer.
Property MultipleOf As %Double(%JSONFIELDNAME = "multipleOf");

/// @JSONSchemaValidation: If the instance is a number, then this keyword validates if "exclusiveMaximum" is true and instance is less than the provided value, or else if the instance is less than or exactly equal to the provided value.
Property Maximum As %Double(%JSONFIELDNAME = "maximum");

/// @JSONSchemaValidation: If "exclusiveMaximum" is true, then a numeric instance SHOULD NOT be equal to the value specified in "maximum".  If "exclusiveMaximum" is false (or not specified), then a numeric instance MAY be equal to the value of "maximum".
Property ExclusiveMaximum As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "exclusiveMaximum");

/// @JSONSchemaValidation:  If the instance is a number, then this keyword validates if "exclusiveMinimum" is true and instance is greater than the provided value, or else if the instance is greater than or exactly equal to the provided value.
Property Minimum As %Double(%JSONFIELDNAME = "minimum");

/// @JSONSchemaValidation: If "exclusiveMinimum" is true, then a numeric instance SHOULD NOT be equal to the value specified in "minimum".  If "exclusiveMinimum" is false (or not specified), then a numeric instance MAY be equal to the value of "minimum".
Property ExclusiveMinimum As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "exclusiveMinimum");

/// @JSONSchemaValidation: A string instance is valid against this keyword if its length is less than, or equal to, the value of this keyword.
Property MaxLength As %Integer(%JSONFIELDNAME = "maxLength");

/// @JSONSchemaValidation: A string instance is valid against this keyword if its length is greater than, or equal to, the value of this keyword.
Property MinLength As %Integer(%JSONFIELDNAME = "minLength");

/// @JSONSchemaValidation: This string SHOULD be a valid regular expression, according to the ECMA 262 regular expression dialect. A string instance is considered valid if the regular expression matches the instance successfully.
Property Pattern As %String(%JSONFIELDNAME = "pattern", MAXLEN = 2000);

/// @JSONSchemaValidation: An array instance is valid against "maxItems" if its size is less than, or equal to, the value of this keyword.
Property MaxItems As %Integer(%JSONFIELDNAME = "maxItems");

/// @JSONSchemaValidation: An array instance is valid against "minItems" if its size is greater than, or equal to, the value of this keyword.
Property MinItems As %Integer(%JSONFIELDNAME = "minItems");

/// @JSONSchemaValidation: If this keyword has boolean value false, the instance validates successfully.  If it has boolean value true, the instance validates successfully if all of its elements are unique.
Property UniqueItems As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "uniqueItems");

/// @JSONSchemaValidation: An object instance is valid against "maxProperties" if its number of properties is less than, or equal to, the value of this keyword.
Property MaxProperties As %Integer(%JSONFIELDNAME = "maxProperties");

/// @JSONSchemaValidation: An object instance is valid against "minProperties" if its number of properties is greater than, or equal to, the value of this keyword.
Property MinProperties As %Integer(%JSONFIELDNAME = "minProperties");

/// @JSONSchemaValidation: An object instance is valid against this keyword if its property set contains all elements in this keyword's array value.
Property Required As %pkg.isc.rest.openAPI.model.stringList(%JSONFIELDNAME = "required");

/// @JSONSchemaValidation: An instance validates successfully against this keyword if its value is equal to one of the elements in this keyword's array value.
Property Enum As %pkg.isc.rest.openAPI.model.stringList(%JSONFIELDNAME = "enum");

/// @JSONSchemaValidation: An instance matches successfully if its primitive type is one of the types defined by keyword.
/// See http://spec.openapis.org/oas/v3.0.3#dataTypes for additional documentation.
Property Type As %String(%JSONFIELDNAME = "type", MAXLEN = 2000);

/// @JSONSchemaValidation: An instance validates successfully against this keyword if it validates successfully against all schemas defined by this keyword's value.
Property AllOf As list Of %pkg.isc.rest.openAPI.model.schemaOrReference(%JSONFIELDNAME = "allOf");

/// @JSONSchemaValidation: An instance validates successfully against this keyword if it validates successfully against exactly one schema defined by this keyword's value.
Property OneOf As list Of %pkg.isc.rest.openAPI.model.schemaOrReference(%JSONFIELDNAME = "oneOf");

/// @JSONSchemaValidation: An instance validates successfully against this keyword if it validates successfully against at least one schema defined by this keyword's value.
Property AnyOf As list Of %pkg.isc.rest.openAPI.model.schemaOrReference(%JSONFIELDNAME = "anyOf");

/// @JSONSchemaValidation: An instance is valid against this keyword if it fails to validate successfully against the schema defined by this keyword.
Property Not As list Of %pkg.isc.rest.openAPI.model.schemaOrReference(%JSONFIELDNAME = "not");

/// Schema (singular) that is allowed in this object when ..Type = "array"
Property Items As %pkg.isc.rest.openAPI.model.schemaOrReference(%JSONFIELDNAME = "items");

/// Mapping from Name->Schema of this object's properties
Property Properties As array Of %pkg.isc.rest.openAPI.model.schemaOrReference(%JSONFIELDNAME = "properties");

/// @JSONSchemaValidation: The value of "additionalProperties" MUST be a boolean or a schema.
/// @JSONSchemaValidation: If "additionalProperties" is false, validation succeeds only if the instance is an object and all properties on the instance were covered by "properties" and/or "patternProperties".
/// @JSONSchemaValidation: If "additionalProperties" is an object, validate the value as a schema to all of the properties that weren't validated by "properties" nor "patternProperties".
/// @JSONSchemaValidation: AdditionalProperties defaults to true when unspecified.
Property AdditionalProperties As %pkg.isc.rest.openAPI.model.genericObject(%JSONFIELDNAME = "additionalProperties");

/// @JSONSchemaValidation: [The description property] can be used to decorate a user interface with information about the data produced by this user interface.
/// @JSONSchemaValidation: [A description] will provide explanation about the purpose of the instance described by this schema 
/// @OpenAPI: CommonMark syntax MAY be used for rich text representation.
Property Description As %String(%JSONFIELDNAME = "description", MAXLEN = 2000);

/// Field that provides additional information on the schema's type.
/// See http://spec.openapis.org/oas/v3.0.3#dataTypeFormat for additional documentation.
Property Format As %String(%JSONFIELDNAME = "format", MAXLEN = 2000);

/// @OpenAPI: The default value represents what would be assumed by the consumer of the input as the value of the schema if one is not provided.
/// @OpenAPI: Unlike JSON Schema, the value MUST conform to the defined type for the Schema Object defined at the same level. For example, if type is string, then default can be "foo" but cannot be 1.
Property Default As %pkg.isc.rest.openAPI.model.genericObject(%JSONFIELDNAME = "default");

/// @OpenAPI: A true value adds "null" to the allowed type specified by the type keyword, only if type is explicitly defined within the same Schema Object. Other Schema Object constraints retain their defined behavior, and therefore may disallow the use of null as a value. A false value leaves the specified or default type unmodified. The default value is false.
Property Nullable As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "nullable");

/// @OpenAPI: Adds support for polymorphism. The discriminator is an object name that is used to differentiate between other schemas which may satisfy the payload description.
/// See http://spec.openapis.org/oas/v3.0.3#schemaComposition for additional documentation.
Property Discriminator As %pkg.isc.rest.openAPI.model.discriminator(%JSONFIELDNAME = "discriminator");

/// @OpenAPI: Relevant only for Schema "properties" definitions. Declares the property as “read only”. This means that it MAY be sent as part of a response but SHOULD NOT be sent as part of the request. If the property is marked as readOnly being true and is in the required list, the required will take effect on the response only. A property MUST NOT be marked as both readOnly and writeOnly being true. Default value is false.
Property ReadOnly As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "readOnly");

/// @OpenAPI: Relevant only for Schema "properties" definitions. Declares the property as “write only”. Therefore, it MAY be sent as part of a request but SHOULD NOT be sent as part of the response. If the property is marked as writeOnly being true and is in the required list, the required will take effect on the request only. A property MUST NOT be marked as both readOnly and writeOnly being true. Default value is false.
Property WriteOnly As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "writeOnly");

/// @OpenAPI: This MAY be used only on properties schemas. It has no effect on root schemas. Adds additional metadata to describe the XML representation of this property.
Property XML As %pkg.isc.rest.openAPI.model.xml(%JSONFIELDNAME = "xml");

/// @OpenAPI: Additional external documentation for this schema.
Property ExternalDocumentation As %pkg.isc.rest.openAPI.model.externalDocumentation(%JSONFIELDNAME = "externalDocs");

/// @OpenAPI: A free-form property to include an example of an instance for this schema. To represent examples that cannot be naturally represented in JSON or YAML, a string value can be used to contain the example with escaping where necessary.
Property Example As %pkg.isc.rest.openAPI.model.genericObject(%JSONFIELDNAME = "example");

/// @OpenAPI: Specifies that a schema is deprecated and SHOULD be transitioned out of usage. Default value is false.
Property Deprecated As %pkg.isc.rest.openAPI.model.boolean(%JSONFIELDNAME = "deprecated");

/// Used to track the ResourceInfoStub used in this schema's creation
Property SourceStub As %pkg.isc.rest.openAPI.resourceInfoStub(%JSONINCLUDE = "none");

/// Used to track the the schema's use ("direction")
Property SourceDirection As %String(%JSONINCLUDE = "none");

/// @Override: Object-specific validation logic within a given OpenAPI Specification (use ..ValidateComponent() for full validation)
Method Validate(fullSpecification As %pkg.isc.rest.openAPI.model.openAPI = "", debug = 0) As %Boolean
{
	Set maxPropertiesValid = 1
	If ..MaxProperties'="" {
		Set maxPropertiesValid = $IsObject(..Properties) && (..Properties.Count() <= ..MaxProperties)
	}
	Set minPropertiesValid = 1
	If ..MinProperties'="" {
		Set minPropertiesValid = '$IsObject(..Properties) || (..Properties.Count() >= ..MinProperties)
	}
	Set exampleTypeValid = 1
	If $IsObject(..Example) {
		// TODO: Check this!
	}
	Set requiredValid = 1
	If $IsObject(..Required) {
		Set map = {}
		For i=1:1:..Required.Count() {
			Set elem = ..Required.GetAt(i)
			If map.%IsDefined(elem) {
				Set requiredValid = 0
				Do ..OnFail(fullSpecification, debug, "List should not contain duplicates, found (" _ ..Required.GetAt(i) _ ")", "Required")
				Quit:'debug
			}
			Do map.%Set(elem,1)
		}
	}
	Set enumValid = 1
	If $IsObject(..Enum) {
		Set map = {}
		For i=1:1:..Enum.Count() {
			Set elem = ..Enum.GetAt(i)
			If map.%IsDefined(elem) {
				Set enumValid = 0
				Do ..OnFail(fullSpecification, debug, "List should not contain duplicates, found (" _ ..Enum.GetAt(i) _ ")", "Enum")
			}
			Do map.%Set(elem,1)
		}
		If ..Enum.Count() = 0 {
			Do ..OnFail(fullSpecification, debug, "Enum list cannot be empty if defined", "Enum")
		}
	}
	Set additionalPropertiesValid = 1
	If ..AdditionalProperties'="" {
		If ..AdditionalProperties.JSONType '= "boolean" {
			If '$IsObject(..AdditionalProperties.Data) {
				Set additionalPropertiesValid = 0
				Do ..OnFail(fullSpecification, debug, "AdditionalProperties must be boolean, Schema, or Schema reference; found other non-object", "AdditionalProperties")
			} Else {
				Set additionalPropertiesValid = $ClassMethod(..AdditionalProperties.Data, "%Extends", "%pkg.isc.rest.openAPI.model.schemaOrReference")
				Do:'additionalPropertiesValid ..OnFail(fullSpecification, debug, "AdditionalProperties must be boolean, Schema, or Schema reference; found other object", "AdditionalProperties")
			}
		}
	}
	Do:'maxPropertiesValid ..OnFail(fullSpecification, debug, "Too many properties specified", "MaxProperties")
	Do:'minPropertiesValid ..OnFail(fullSpecification, debug, "Too few properties specified", "MinProperties")
	Do:'exampleTypeValid ..OnFail(fullSpecification, debug, "Example type does not match schema type", "Example")
	Return maxPropertiesValid && minPropertiesValid && exampleTypeValid && requiredValid && enumValid && additionalPropertiesValid
}

Method RemoveAllFromSource(className As %String, Output keepSelf As %Boolean)
{
	Set sourceID = ..SourceClasses.Find(className)
	If sourceID="" {
		Set keepSelf = 1
		Return
	}
	
	Set key="", property = ..Properties.GetNext(.key)
	While key'="" {
		Do property.RemoveAllFromSource(className, .keep)
		If 'keep {
			Do ..Properties.RemoveAt(key)
			Set key = ""
		}
	}
	For i=1:1:..AllOf.Count() {
		Quit:i>..AllOf.Count()
		Do ..AllOf.GetAt(i).RemoveAllFromSource(className, .keep)
		If 'keep {
			Do ..AllOf.RemoveAt(i)
			Set i = i-1
		}
	}
	For i=1:1:..OneOf.Count() {
		Quit:i>..OneOf.Count()
		Do ..OneOf.GetAt(i).RemoveAllFromSource(className, .keep)
		If 'keep {
			Do ..OneOf.RemoveAt(i)
			Set i = i-1
		}
	}
	For i=1:1:..AnyOf.Count() {
		Quit:i>..AnyOf.Count()
		Do ..AnyOf.GetAt(i).RemoveAllFromSource(className, .keep)
		If 'keep {
			Do ..AnyOf.RemoveAt(i)
			Set i = i-1
		}
	}
	For i=1:1:..Not.Count() {
		Quit:i>..Not.Count()
		Do ..Not.GetAt(i).RemoveAllFromSource(className, .keep)
		If 'keep {
			Do ..Not.RemoveAt(i)
			Set i = i-1
		}
	}
	If $IsObject(..Items) {
		Do ..Items.RemoveAllFromSource(className, .keep)
		Set:'keep ..Items = ""
	}
	
	Do ..SourceClasses.RemoveAt(sourceID)
	Set keepSelf = ..SourceClasses.Count()
}

Storage Default
{
<Data name="Extras">
<Attribute>Extras</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.schema.Extras"</Subscript>
</Data>
<Data name="Properties">
<Attribute>Properties</Attribute>
<Structure>subnode</Structure>
<Subscript>"%pkg.isc.rest.openAPI.model.schema.Properties"</Subscript>
</Data>
<Data name="SchemaDefaultData">
<Subscript>"Schema"</Subscript>
<Value name="1">
<Value>Title</Value>
</Value>
<Value name="2">
<Value>MultipleOf</Value>
</Value>
<Value name="3">
<Value>Maximum</Value>
</Value>
<Value name="4">
<Value>ExclusiveMaximum</Value>
</Value>
<Value name="5">
<Value>Minimum</Value>
</Value>
<Value name="6">
<Value>ExclusiveMinimum</Value>
</Value>
<Value name="7">
<Value>MaxLength</Value>
</Value>
<Value name="8">
<Value>MinLength</Value>
</Value>
<Value name="9">
<Value>Pattern</Value>
</Value>
<Value name="10">
<Value>MaxItems</Value>
</Value>
<Value name="11">
<Value>MinItems</Value>
</Value>
<Value name="12">
<Value>UniqueItems</Value>
</Value>
<Value name="13">
<Value>MaxProperties</Value>
</Value>
<Value name="14">
<Value>MinProperties</Value>
</Value>
<Value name="15">
<Value>Required</Value>
</Value>
<Value name="16">
<Value>Enum</Value>
</Value>
<Value name="17">
<Value>Type</Value>
</Value>
<Value name="18">
<Value>AllOf</Value>
</Value>
<Value name="19">
<Value>OneOf</Value>
</Value>
<Value name="20">
<Value>AnyOf</Value>
</Value>
<Value name="21">
<Value>Not</Value>
</Value>
<Value name="22">
<Value>Items</Value>
</Value>
<Value name="23">
<Value>AdditionalProperties</Value>
</Value>
<Value name="24">
<Value>Description</Value>
</Value>
<Value name="25">
<Value>Format</Value>
</Value>
<Value name="26">
<Value>Default</Value>
</Value>
<Value name="27">
<Value>Nullable</Value>
</Value>
<Value name="28">
<Value>Discriminator</Value>
</Value>
<Value name="29">
<Value>ReadOnly</Value>
</Value>
<Value name="30">
<Value>WriteOnly</Value>
</Value>
<Value name="31">
<Value>XML</Value>
</Value>
<Value name="32">
<Value>ExternalDocumentation</Value>
</Value>
<Value name="33">
<Value>Example</Value>
</Value>
<Value name="34">
<Value>Deprecated</Value>
</Value>
<Value name="35">
<Value>SourceStub</Value>
</Value>
<Value name="36">
<Value>SourceDirection</Value>
</Value>
</Data>
<DefaultData>SchemaDefaultData</DefaultData>
<Type>%Storage.Persistent</Type>
}

}

