Class isc.sample.rest.phonebook.model.Person Extends (%Persistent, %Populate, %pkg.isc.json.adaptor, %pkg.isc.rest.model.adaptor)
{

Parameter RESOURCENAME = "contact";

Parameter %JSONINCLUDEID = 1;

Property Name As %String(%JSONFIELDNAME = "name");

Relationship PhoneNumbers As isc.sample.rest.phonebook.model.PhoneNumber(%JSONFIELDNAME = "phones", %JSONINCLUDE = "outputonly", %JSONREFERENCE = "object") [ Cardinality = children, Inverse = Person ];

/// Checks the user's permission for a particular operation on a particular record.
/// <var>pOperation</var> may be one of:
/// CREATE
/// READ
/// UPDATE
/// DELETE
/// QUERY
/// ACTION:<action name>
/// <var>pUserContext</var> is supplied by <method>GetUserContext</method>
ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As %pkg.isc.rest.authentication.platformUser) As %Boolean
{
	Quit (pOperation = "QUERY") || (pOperation = "READ") || (pOperation = "CREATE") || (pOperation = "UPDATE") ||
        (pOperation = "ACTION:add-phone") || (pOperation = "ACTION:find-by-phone")
}

Method AddPhoneNumber(phoneNumber As isc.sample.rest.phonebook.model.PhoneNumber) As isc.sample.rest.phonebook.model.Person
{
    Set phoneNumber.Person = $This
    $$$ThrowOnError(phoneNumber.%Save())
    Quit $This
}

Query FindByPhone(phoneFragment As %String) As %SQLQuery
{
select distinct Person
from isc_sample_rest_phonebook_model.PhoneNumber
where $Translate(PhoneNumber,' -+()') [ $Translate(:phoneFragment,' -+()')
}

XData ActionMap [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/rest/action" ]
{
<actions xmlns="http://www.intersystems.com/_pkg/isc/rest/action">
<action name="add-phone" target="instance" method="POST" call="AddPhoneNumber">
<argument name="phoneNumber" target="phoneNumber" source="body" />
</action>

<action name="find-by-phone" target="class" method="GET" query="FindByPhone">
<argument name="phoneFragment" target="phoneFragment" source="query" />
</action>
</actions>
}

Storage Default
{
<Data name="PersonDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
</Data>
<DataLocation>^Sample.Phonebook.Model.PersonD</DataLocation>
<DefaultData>PersonDefaultData</DefaultData>
<IdLocation>^Sample.Phonebook.Model.PersonD</IdLocation>
<IndexLocation>^Sample.Phonebook.Model.PersonI</IndexLocation>
<StreamLocation>^Sample.Phonebook.Model.PersonS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
