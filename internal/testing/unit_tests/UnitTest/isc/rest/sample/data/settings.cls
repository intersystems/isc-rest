/// Singleton settings class.
Class UnitTest.isc.rest.sample.data.settings Extends (%Persistent, %pkg.isc.rest.abstractSingleton)
{

/// %JSONFIELDNAMEASCAMELCASE auto-generates the %JSONFIELDNAME for properties (if not specified)
/// as camelCase.
Parameter %JSONFIELDNAMEASCAMELCASE As BOOLEAN = 1;

Property Timeout As %Integer [ InitialExpression = 90 ];

Property UnauthenticatedEnabled As %Boolean [ InitialExpression = 0 ];

Property SystemMode As %String [ InitialExpression = "Test" ];

Storage Default
{
<Data name="settingsDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Classname</Value>
</Value>
<Value name="3">
<Value>Timeout</Value>
</Value>
<Value name="4">
<Value>UnauthenticatedEnabled</Value>
</Value>
<Value name="5">
<Value>SystemMode</Value>
</Value>
</Data>
<DataLocation>^UnitTest.isc.rest6EBF.settingsD</DataLocation>
<DefaultData>settingsDefaultData</DefaultData>
<IdLocation>^UnitTest.isc.rest6EBF.settingsD</IdLocation>
<IndexLocation>^UnitTest.isc.rest6EBF.settingsI</IndexLocation>
<StreamLocation>^UnitTest.isc.rest6EBF.settingsS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

