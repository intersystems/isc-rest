Class UnitTest.isc.rest.openAPI.nonTransientResource Extends (%Persistent, %pkg.isc.rest.model.dbMappedResource)
{

Parameter RESOURCENAME = "unittest-isc-rest-openapi-nontransient-resource";

Parameter MEDIATYPE = "application/vnd.intersystems.apps.unittest.nontransient.resource+json";

Property TestProperty As %String;

Storage Default
{
<Data name="nonTransientResourceDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>TestProperty</Value>
</Value>
</Data>
<DataLocation>^UnitTest.i7019.nonTransien7281D</DataLocation>
<DefaultData>nonTransientResourceDefaultData</DefaultData>
<IdLocation>^UnitTest.i7019.nonTransien7281D</IdLocation>
<IndexLocation>^UnitTest.i7019.nonTransien7281I</IndexLocation>
<StreamLocation>^UnitTest.i7019.nonTransien7281S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

