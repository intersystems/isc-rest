Class UnitTest.isc.rest.samplePersistentAdapted Extends (%Persistent, %pkg.isc.rest.model.adaptor)
{

/// Name of the resource at the REST level
/// Subclasses MUST override this
Parameter RESOURCENAME As STRING = "unittest-sample-persistent-adapted";

Parameter JSONMAPPING As STRING = "FooBarMapping";

XData FooBarMapping [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/json/jsonmapping" ]
{
<Mapping xmlns="http://www.intersystems.com/_pkg/isc/json/jsonmapping">
 <Property Name="Foo" FieldName="someField" />
 <Property Name="Bar" />
 <!-- Baz intentionally omitted. -->
 <Property Name="Another" Include="none" />
</Mapping>
}

Property Foo As %String [ SqlFieldName = FOO_NAME ];

Property Bar As %String;

Property Baz As %String;

Property Another As %String;

Storage Default
{
<Data name="samplePersistentAdaptedDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Foo</Value>
</Value>
<Value name="3">
<Value>Bar</Value>
</Value>
<Value name="4">
<Value>Baz</Value>
</Value>
<Value name="5">
<Value>Another</Value>
</Value>
</Data>
<DataLocation>^UnitTest.iB464.samplePersiA6A8D</DataLocation>
<DefaultData>samplePersistentAdaptedDefaultData</DefaultData>
<IdLocation>^UnitTest.iB464.samplePersiA6A8D</IdLocation>
<IndexLocation>^UnitTest.iB464.samplePersiA6A8I</IndexLocation>
<StreamLocation>^UnitTest.iB464.samplePersiA6A8S</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

