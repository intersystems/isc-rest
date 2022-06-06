Class isc.sample.rest.phonebook.model.PhoneNumber Extends (%Persistent, %Populate, %pkg.isc.json.adaptor)
{

Parameter %JSONINCLUDEID = 1;

Relationship Person As isc.sample.rest.phonebook.model.Person(%JSONINCLUDE = "none") [ Cardinality = parent, Inverse = PhoneNumbers ];

Property PhoneNumber As %String(%JSONFIELDNAME = "number", POPSPEC = "USPhone()");

Property Type As %String(%JSONFIELDNAME = "type", VALUELIST = ",Mobile,Home,Office");

XData PhoneNumberWithPerson [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/json/jsonmapping" ]
{
<Mapping xmlns="http://www.intersystems.com/_pkg/isc/json/jsonmapping">
<Property Name="Person" FieldName="person" Include="inputonly" Reference="ID" />
<Property Name="PhoneNumber" FieldName="number" />
<Property Name="Type" FieldName="type" />
</Mapping>
}

Storage Default
{
<Data name="PhoneNumberDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>PhoneNumber</Value>
</Value>
<Value name="3">
<Value>Type</Value>
</Value>
</Data>
<DataLocation>{%%PARENT}("PhoneNumbers")</DataLocation>
<DefaultData>PhoneNumberDefaultData</DefaultData>
<IdLocation>^Sample.Phonebook.Model.PersonC("PhoneNumbers")</IdLocation>
<IndexLocation>^Sample.Phonebo6771.PhoneNumberI</IndexLocation>
<StreamLocation>^Sample.Phonebo6771.PhoneNumberS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
