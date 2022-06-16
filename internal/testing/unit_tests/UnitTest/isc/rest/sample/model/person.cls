Class UnitTest.isc.rest.sample.model.person Extends %pkg.isc.rest.model.proxy [ DependsOn = UnitTest.isc.rest.sample.data.person ]
{

/// The class to which this class provides REST access. It must extend %Persistent and have its %JSONENABLED class parameter set to 1 (e.g., by extending %JSON.Adaptor).
/// Subclasses must override this parameter.
Parameter SOURCECLASS As STRING = "UnitTest.isc.rest.sample.data.person";

/// The JSON mapping of the related JSON-enabled class to use.
/// Defaults to empty (the default mapping for the associated class).
Parameter JSONMAPPING As STRING = "LimitedInfo";

/// Name of the resource at the REST level
/// Subclasses MUST override this
Parameter RESOURCENAME As STRING = "person";

/// Set to 1 to treat this resource as the default for its name, to permit flexible matching on Accept header
Parameter DEFAULT As BOOLEAN = 1;

/// Permits READ and QUERY access only.
ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As UnitTest.isc.rest.sample.userContext) As %Boolean
{
	If pUserContext.IsAdmin {
		// An admin can do anything.
		Quit 1
	}	
	If (pUserContext.Username = ##class(UnitTest.isc.rest.sample.data.person).UsernameGetStored(pID)) {
		// The current user can do anything to their own record except delete it.
		Quit (pOperation '= $$$OperationDelete)
	}
	Quit (pOperation = $$$OperationRead) || (pOperation = $$$OperationQuery)
}

/// Defines a mapping of actions available for this model class to the associated methods and arguments.
XData ActionMap [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/rest/action" ]
{
<actions xmlns="http://www.intersystems.com/_pkg/isc/rest/action">
<!-- Class query ByName in UnitTest.isc.rest.sample.data.person, but projected as this model class (LimitedInfo). -->
<action name="list-by-name" target="class" method="GET" query="UnitTest.isc.rest.sample.data.person:ByName"
modelClass="UnitTest.isc.rest.sample.model.person">
<argument name="name" target="name" />
</action>

<!-- Could also make name required: -->
<action name="alt-list-by-name" method="GET" query="UnitTest.isc.rest.sample.data.person:ByName"
modelClass="UnitTest.isc.rest.sample.model.person">
<argument name="name" target="name" required="true" />
</action>

<!-- Updates a person's home address -->
<action name="update-home-address" method="PUT" target="instance" call="UpdateHomeAddress">
<argument name="id" target="pID" source="id" />
<argument name="address" target="pAddress" source="body" />
</action>

<!-- Updates a person's office address -->
<action name="update-office-address" method="POST" target="instance"
call="UnitTest.isc.rest.sample.model.person:UpdateOfficeAddress">
<!-- Note above, can also include class name in call attribute. -->
<argument name="id" target="pID" source="id" />
<argument name="address" target="pAddress" source="body" />
</action>

<!-- Can also use raw dynamic objects for automatic serialization/deserialization, but types are recommended. -->
<action name="ping" method="POST" call="Ping">
<argument name="whatever" source="body" target="pObject" />
</action>

<!-- Pass path parameter -->
<action name="path-param/:first/hello/:second/:third/world" method="POST" call="TestPathParameter">
<argument name="first" source="path" target="pFirst" />
<argument name="second" source="path" target="pSecond" />
<argument name="third" source="path" target="pThird" />
</action>

</actions>
}

ClassMethod UpdateHomeAddress(pID As %String, pAddress As UnitTest.isc.rest.sample.data.address) As UnitTest.isc.rest.sample.data.address
{
	Set person = ##class(UnitTest.isc.rest.sample.data.person).%OpenId(pID,,.sc)
	$$$ThrowOnError(sc)
	Set person.Home = pAddress
	$$$ThrowOnError(person.%Save())
	Quit person.Home
}

ClassMethod UpdateOfficeAddress(pID As %String, pAddress As UnitTest.isc.rest.sample.data.address) As UnitTest.isc.rest.sample.model.person
{
	Set person = ##class(UnitTest.isc.rest.sample.data.person).%OpenId(pID,,.sc)
	$$$ThrowOnError(sc)
	Set person.Office = pAddress
	$$$ThrowOnError(person.%Save())
	Quit ..GetModelInstance(pID)
}

ClassMethod Ping(pObject As %DynamicAbstractObject) As %DynamicAbstractObject
{
	Quit pObject
}

ClassMethod TestPathParameter(pFirst As %String, pSecond As %String, pThird As %String) As %DynamicAbstractObject
{
	Quit {
		"first": (pFirst),
		"second": (pSecond),
		"third": (pThird)
	}
}

Method %Id()
{
	// Workaround for needing more generic source="id" support.
	Quit ..%instance.%Id()
}

}

