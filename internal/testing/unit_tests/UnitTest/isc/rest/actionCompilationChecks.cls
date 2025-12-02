/// Tests compile-time validation of ActionMaps.
/// zpm "isc.rest test -only -DUnitTest.Case=UnitTest.isc.rest.actionCompilationChecks"
Class UnitTest.isc.rest.actionCompilationChecks Extends UnitTest.isc.rest.testCase
{

/// Tests all options for return types for an action. For each return type,
/// there is a separate XData ActionMap blog 
Method TestReturnTypes()
{
    // Each test below is the name of a corresponding method + XData block
    // combination present in this class
    Set testList = $ListBuild(
        "ReturnTypeString",
        "ReturnTypeInteger",
        "ReturnTypeTimestamp",
        "ReturnTypeList",
        "ReturnTypeDynamicObject",
        // TODO: "ReturnTypeResource",
        // TODO: "ReturnTypeQueryResult",
        // TODO: "ReturnTypeCSPStream",
        // TODO: "ReturnTypeStream",
        // TODO: "ReturnTypeJSONEnabledRegistered",
        // TODO: "ReturnTypeJSONEnabledNonRegistered",
        // TODO: "ReturnTypeListOfDataTypes",
        // TODO: "ReturnTypeListOfObjects",
        // TODO: "ReturnTypeArrayOfDataTypes",
        // TODO: "ReturnTypeArrayOfObjects",
    )
    Set ptr = 0
    While $ListNext(testList, ptr, test) {
        If ($Get(test) = "") {
            // Skip empty ones
            Continue
        }
        Set classname = "zUnitTest.isc.rest." _ test
        Do ..SetupClass(
            classname,
            ["%pkg.isc.rest.model.resource"],
            { "RESOURCENAME": (test) },
            /* propertyName */,
            /* propertyFields */,
            /* propertyParameters */,
            /* relationsshipName */,
            /* relationshipFields */,
            /* relationshipParameters */,
            [ (test_":ActionMap") ],
            [ (test) ],
            /* clonedQueries */,
            /* classDescription */
        )
        Set sc = ..CompileClass(classname)
        Do $$$AssertEquals(sc,$$$OK,"Compilation success for "_classname)
    }
}

Method TestMissingMembers()
{
    // Missing class method

    Do ..SetupClass(
        "zUnitTest.isc.rest.ReturnTypeDynamicObject",
        ["%pkg.isc.rest.model.resource"],
        { "RESOURCENAME": "ReturnTypeDynamicObject" },
        /* propertyName */,
        /* propertyFields */,
        /* propertyParameters */,
        /* relationsshipName */,
        /* relationshipFields */,
        /* relationshipParameters */,
        [ "ReturnTypeDynamicObject:ActionMap" ],
        /* clonedMethods */
        /* clonedQueries */,
        /* classDescription */
    )
    Set sc = ..CompileClass("zUnitTest.isc.rest.ReturnTypeDynamicObject")
    Set error = "Method 'ReturnTypeDynamicObject' is missing in class 'zUnitTest.isc.rest.ReturnTypeDynamicObject' but expected as part of action 'return-type-dynamic-object'"
    Do $$$AssertTrue(($System.Status.GetErrorText(sc) [ error),"Missing method success")

    // TODO: Missing class query
}

Method TestActionSyntax()
{
    // TODO: Action with no call and no query

    // TODO: Action with call and modelClass

    // TODO: Action with query and method other than GET

    // TODO: Action with : but not right after /

    // TODO: Action with duplicate path parameters
}

Method TestActionArgumentSyntax()
{

    // TODO: Multiple source=body arguments

    // TODO: Duplicate arg name + source combination

    // TODO: Duplicate target

    // TODO: Path argument missing in action name

    // TODO: Path argument in action name but missing in arguments
}

XData ReturnTypeDynamicObject [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/rest/action" ]
{
<actions xmlns="http://www.intersystems.com/_pkg/isc/rest/action">
<action name="return-type-dynamic-object" target="class" call="ReturnTypeDynamicObject">
</action>
</actions>
}

ClassMethod ReturnTypeDynamicObject() As %DynamicObject
{
    Return { "test": "return dynamic object" }
}

XData ReturnTypeString [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/rest/action" ]
{
<actions xmlns="http://www.intersystems.com/_pkg/isc/rest/action">
<action name="return-type-string" target="class" call="ReturnTypeString">
</action>
</actions>
}

ClassMethod ReturnTypeString() As %CSP.Stream(MEDIATYPE="hello")
{
    Return "return a string"
}

XData ReturnTypeInteger [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/rest/action" ]
{
<actions xmlns="http://www.intersystems.com/_pkg/isc/rest/action">
<action name="return-type-integer" target="class" call="ReturnTypeInteger">
</action>
</actions>
}

ClassMethod ReturnTypeInteger() As %Integer
{
    Return 42
}

XData ReturnTypeTimestamp [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/rest/action" ]
{
<actions xmlns="http://www.intersystems.com/_pkg/isc/rest/action">
<action name="return-type-timestamp" target="class" call="ReturnTypeTimestamp">
</action>
</actions>
}

ClassMethod ReturnTypeTimestamp() As %TimeStamp
{
    Return ##class(%Library.UTC).NowUTC()
}

XData ReturnTypeList [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/rest/action" ]
{
<actions xmlns="http://www.intersystems.com/_pkg/isc/rest/action">
<action name="return-type-list" target="class" call="ReturnTypeList">
</action>
</actions>
}

ClassMethod ReturnTypeList() As %List
{
    Return $ListBuild("this", "is", "a", "list")
}

}

