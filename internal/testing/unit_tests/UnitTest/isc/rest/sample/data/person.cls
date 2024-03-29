/// Use or operation of this code is subject to acceptance of the license available in the code repository for this code.
/// This sample persistent class represents a person.
Class UnitTest.isc.rest.sample.data.person Extends (%Persistent, %Populate, %XML.Adaptor, %pkg.isc.json.adaptor)
{

Parameter EXTENTQUERYSPEC = "Name,SSN,Home.City,Home.State";

/// Define a unique index for <property>SSN</property>.
Index SSNKey On SSN [ Type = index, Unique ];

/// Define an index for <property>Name</property>.
Index NameIDX On Name [ Data = Name ];

/// Define an index for embedded object property <b>ZipCode</b>.
Index ZipCode On Home.Zip [ Type = bitmap ];

/// Person's name.
Property Name As %String(POPSPEC = "Name()") [ Required ];

/// Person's Social Security number. This is validated using pattern match.
Property SSN As %String(PATTERN = "3N1""-""2N1""-""4N");

/// Person's Date of Birth.
Property DOB As %Date(POPSPEC = "Date()");

/// Person's home address. This uses an embedded object.
Property Home As UnitTest.isc.rest.sample.data.address;

/// Person's office address. This uses an embedded object.
Property Office As UnitTest.isc.rest.sample.data.address;

/// Person's spouse. This is a reference to another persistent object.
Property Spouse As UnitTest.isc.rest.sample.data.person;

/// A collection of strings representing the person's favorite colors.
Property FavoriteColors As list Of %String(JAVATYPE = "java.util.List", POPSPEC = "ValueList("",Red,Orange,Yellow,Green,Blue,Purple,Black,White""):2");

/// Person's age.<br>
/// This is a calculated field whose value is derived from <property>DOB</property>.
Property Age As %Integer [ Calculated, SqlComputeCode = { Set {Age}=##class(UnitTest.isc.rest.sample.data.person).CurrentAge({DOB})
}, SqlComputed, SqlComputeOnChange = DOB ];

/// This class method calculates a current age given a date of birth <var>date</var>.
/// This method is used by the Age calculated field.
ClassMethod CurrentAge(date As %Date = "") As %Integer [ CodeMode = expression ]
{
$Select(date="":"",1:($ZD($H,8)-$ZD(date,8)\10000))
}

/// A sample class query that defines a result set that returns Person data 
/// ordered by <property>Name</property>.<br>
/// This query can be used within another method (using 
/// dynamic SQL), or it can be used from Java.<br>
/// This query is also accessible from JDBC and/or ODBC as the SQL stored procedure 
/// <b>SP_Sample_By_Name</b>.
Query ByName(name As %String = "") As %SQLQuery(CONTAINID = 1, SELECTMODE = "RUNTIME") [ SqlName = SP_Sample_By_Name, SqlProc ]
{
SELECT ID, Name, DOB, SSN
FROM UnitTest_isc_rest_sample_data.person
WHERE (Name %STARTSWITH :name)
ORDER BY Name
}

XData LimitedInfo [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/json/jsonmapping" ]
{
<Mapping xmlns="http://www.intersystems.com/_pkg/isc/json/jsonmapping">
<Property Name="Name" FieldName="name" />
<Property Name="Age" FieldName="age" Include="OUTPUTONLY" />
<Property Name="Spouse" FieldName="spouse" Reference="ID" />
<Property Name="Office" FieldName="office_address" Reference="OBJECT" />
</Mapping>
}

Storage Default
{
<Data name="personDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Name</Value>
</Value>
<Value name="3">
<Value>SSN</Value>
</Value>
<Value name="4">
<Value>DOB</Value>
</Value>
<Value name="5">
<Value>Home</Value>
</Value>
<Value name="6">
<Value>Office</Value>
</Value>
<Value name="7">
<Value>Spouse</Value>
</Value>
<Value name="8">
<Value>FavoriteColors</Value>
</Value>
</Data>
<DataLocation>^UnitTest.isc.rest.s6EBF.personD</DataLocation>
<DefaultData>personDefaultData</DefaultData>
<IdLocation>^UnitTest.isc.rest.s6EBF.personD</IdLocation>
<IndexLocation>^UnitTest.isc.rest.s6EBF.personI</IndexLocation>
<StreamLocation>^UnitTest.isc.rest.s6EBF.personS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}

