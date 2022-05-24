Class UnitTest.isc.rest.authorization.permission.samplePermission Extends %pkg.isc.rest.authorization.permission
{

/// Name of the resource at the REST level
/// Subclasses MUST override this
Parameter RESOURCENAME As STRING = "unit-test-permission";

Storage Default
{
<Data name="samplePermissionDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>ResourceClass</Value>
</Value>
<Value name="3">
<Value>Context</Value>
</Value>
<Value name="4">
<Value>Operation</Value>
</Value>
</Data>
<DataLocation>^UnitTest.i78CC.samplePermiA3ACD</DataLocation>
<DefaultData>samplePermissionDefaultData</DefaultData>
<IdLocation>^UnitTest.i78CC.samplePermiA3ACD</IdLocation>
<IndexLocation>^UnitTest.i78CC.samplePermiA3ACI</IndexLocation>
<StreamLocation>^UnitTest.i78CC.samplePermiA3ACS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

