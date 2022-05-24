Class isc.sample.rest.phonebook.rest.model.PhoneNumber Extends %pkg.isc.rest.model.proxy [ DependsOn = isc.sample.rest.phonebook.model.PhoneNumber ]
{

Parameter RESOURCENAME = "phone-number";

Parameter SOURCECLASS = "isc.sample.rest.phonebook.model.PhoneNumber";

Parameter JSONMAPPING = "PhoneNumberWithPerson";

ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As %pkg.isc.rest.authentication.platformUser) As %Boolean
{
	Quit (pOperation = "CREATE") || (pOperation = "UPDATE") || (pOperation = "DELETE")
}

}
