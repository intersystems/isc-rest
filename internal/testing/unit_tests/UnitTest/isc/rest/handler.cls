/// Tests for <class>%pkg.isc.rest.handler</class> by emulating the requests
/// to the dispatch class.
/// zpm "isc.rest test -only -DUnitTest.Case=UnitTest.isc.rest.handler"
Class UnitTest.isc.rest.handler Extends UnitTest.isc.rest.testCase [ DependsOn = (UnitTest.isc.rest.sample.handler, UnitTest.isc.rest.sample.userContext) ]
{

/// Subclasses must override this parameter to define the application's REST handler class that is to be tested.
Parameter RESTHandlerClass As CLASSNAME = "UnitTest.isc.rest.sample.handler";

/// Defines the class used as the "user" in the app
Parameter RequesterClass As CLASSNAME = "UnitTest.isc.rest.sample.userContext";

/// Number of people to generate data for.
Parameter PersonCount As INTEGER = 100;

Property Person As %DynamicAbstractObject;

Property Vendor As %DynamicAbstractObject;

Method OnBeforeAllTests() As %Status
{
    Set sc = $$$OK
    Try {
        // Generate data for tests
        Do ##class(UnitTest.isc.rest.sample.data.utils).Generate(..#PersonCount)
    } Catch e {
        Set sc = e.AsStatus()
    }
    Quit sc
}

Method OnAfterAllTests() As %Status
{
    Set sc = $$$OK
    Try {
        // Cleanup data used for tests
        Do ##class(UnitTest.isc.rest.sample.data.utils).CleanupData()
    } Catch e {
        Set sc = e.AsStatus()
    }
    Quit sc
}

Method TestAuthStatus()
{
    #dim response As %CSP.Response
    Do ..Request("GET", "auth/status", , .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(%CSP.REST).#CONTENTTYPEJSON)
    Do $$$AssertEquals(object.Username,$Username)
    Do $$$AssertEquals(object.IsAdmin,(","_$Roles_",") [ ",%All,")
}

Method TestPerson01Query()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Set request.Data("$orderBy", 1) = "name"
    Do ..Request("GET", "person", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE)
    If '$$$AssertEquals(object.%Size(), 200) {
        Do $$$LogMessage("Response Size: "_object.%Size)
    }
}

Method TestPerson011QueryDefault()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = "*/*"
    Set request.Data("$orderBy", 1) = "name"
    Do ..Request("GET", "person", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE)
    If '$$$AssertEquals(object.%Size(), 200) {
        Do $$$LogMessage("Response Size: "_object.%Size)
    }
}

Method TestPerson02Get()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Do ..Request("GET", "person/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE)
    Set ..Person = object
}

Method TestPerson021GetDefault()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = "application/*"
    Do ..Request("GET", "person/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE)
    Set ..Person = object
}

Method TestPerson03Put()
{
    Set name = "Rubble, Barney"
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE
    // Even though string isn't used, write to it to ensure %ToJSON doesn't write to current device
    Set ..Person.name = name
    Set stream = ##class(%Stream.TmpCharacter).%New()
    Set string = ..Person.%ToJSON(.stream)
    Set request.Content = stream
    Do ..Request("PUT", "person/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE)
    Do $$$AssertEquals(object.name, name)
}

Method TestPerson04Post()
{
    Set name = "Flintstone, Fred"
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE
    // Even though string isn't used, write to it to ensure %ToJSON doesn't write to current device
    Set stream = ##class(%Stream.TmpCharacter).%New()
    Set string = {"name": (name)}.%ToJSON(.stream)
    Set request.Content = stream
    Do ..Request("POST", "person", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP201CREATED)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE)
    Do $$$AssertEquals(object.name, name)
}

Method TestPerson05ListByName()
{
    Set name = "Flintstone, Fred"
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Set request.Data("name", 1) = "Flintstone"
    Do ..Request("GET", "person/$list-by-name", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE)
    Do $$$AssertEquals(object.%Size(), 1)
}

Method TestPerson06UpdateHomeAddress()
{
    Set zip = "12345"
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Set request.ContentType = ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE
    // Even though string isn't used, write to it to ensure %ToJSON doesn't write to current device
    Set stream = ##class(%Stream.TmpCharacter).%New()
    Set string = {"Zip": (zip)}.%ToJSON(.stream)
    Set request.Content = stream
    Do ..Request("PUT", "person/201/$update-home-address", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE)
    Do $$$AssertEquals(object.Zip,"12345")
}

Method TestPerson07UpdateOfficeAddress()
{
    Set zip = "02144"
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Set request.ContentType = ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE
    // Even though string isn't used, write to it to ensure %ToJSON doesn't write to current device
    Set stream = ##class(%Stream.TmpCharacter).%New()
    Set string = {"Zip": (zip)}.%ToJSON(.stream)
    Set request.Content = stream
    Do ..Request("POST", "person/201/$update-office-address", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE)
    Do $$$AssertEquals(object."office_address".Zip, zip)
}

Method TestPerson08Ping()
{
    Set value = "bar"
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Set request.ContentType = ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE
    // Even though string isn't used, write to it to ensure %ToJSON doesn't write to current device
    Set stream = ##class(%Stream.TmpCharacter).%New()
    Set string = {"foo": (value)}.%ToJSON(.stream)
    Set request.Content = stream
    Do ..Request("POST", "person/$ping", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE)
    Do $$$AssertEquals(object.foo, value)
}

Method TestPerson09Delete()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE
    Set url = "person/201"
    Do ..Request("DELETE", url, .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP204NOCONTENT)
    Do ..Request("DELETE", url, .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP404NOTFOUND)
}

Method TestPerson10TestPathParameter()
{
    Set route = "person/$path-param/1/hello/2/3/world"
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Set request.URL = "http://test/"_route
    Do ..Request("POST", route, .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE)
    Do $$$AssertEquals(object.first, 1)
    Do $$$AssertEquals(object.second, 2)
    Do $$$AssertEquals(object.third, 3)
}

Method TestVendor1Query()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Do ..Request("GET", "vendor", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.data.vendor).#MEDIATYPE)
    If '$$$AssertEquals(object.%Size(), 100) {
        Do $$$LogMessage("Response Size: "_object.%Size)
    }
}

Method TestVendor2Get()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Do ..Request("GET", "vendor/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.data.vendor).#MEDIATYPE)
    Set ..Vendor = object
}

Method TestVendor3Put()
{
    Set name = "Acme Pharmaceuticals"
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = ##class(UnitTest.isc.rest.sample.data.vendor).#MEDIATYPE
    // Even though string isn't used, write to it to ensure %ToJSON doesn't write to current device
    Set ..Vendor.Name = name
    Set stream = ##class(%Stream.TmpCharacter).%New()
    Set string = ..Vendor.%ToJSON(.stream)
    Set request.Content = stream
    Do ..Request("PUT", "vendor/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.data.vendor).#MEDIATYPE)
    Do $$$AssertEquals(object.Name, name)
}

Method TestVendor4Post()
{
    Set name = "Acme Robotics"
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = ##class(UnitTest.isc.rest.sample.data.vendor).#MEDIATYPE
    // Even though string isn't used, write to it to ensure %ToJSON doesn't write to current device
    Set stream = ##class(%Stream.TmpCharacter).%New()
    Set string = {"Name": (name)}.%ToJSON(.stream)
    Set request.Content = stream
    Do ..Request("POST", "vendor", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP201CREATED)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.data.vendor).#MEDIATYPE)
    Do $$$AssertEquals(object.Name, name)
}

Method TestVendor5Delete()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = ##class(UnitTest.isc.rest.sample.data.vendor).#MEDIATYPE
    Set url = "vendor/101"
    Do ..Request("DELETE", url, .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP204NOCONTENT)
    Do ..Request("DELETE", url, .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP404NOTFOUND)
}

Method TestVendor6Construct()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Do ..Request("GET", "vendor/$new", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.data.vendor).#MEDIATYPE)
    Do $$$AssertEquals(object.%Size(),1)
}

Method TestSettings1UserExpandedInfo()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Do ..Request("GET", "settings/$expanded-user-info", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)
    Do $$$AssertEquals(response.ContentType, "application/json")
    Do $$$AssertEquals(object.UsernameUpper,$ZConvert($Username,"U"))
}

Method TestBad01InvalidOrderBy()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Set request.Data("$orderBy", 1) = "-SSN"
    Do ..Request("GET", "person", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP400BADREQUEST)
    Do $$$AssertEquals(object.errors.%Get(0).params.%Get(0), "Invalid query. Column 'SSN' does not exist.")
}

Method TestBad02MalformedFilter()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Set request.Data("name[foo]", 1) = "Fred"
    Do ..Request("GET", "person", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP400BADREQUEST)
    Do $$$AssertEquals(response.ContentType, ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE)
    Do $$$AssertEquals(object.errors.%Get(0).params.%Get(0), "Invalid query. The parameter value 'name[foo]=Fred' could not be parsed.")
}

Method TestBad03NoResource()
{
    #dim request As %CSP.Request

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Do ..Request("GET", "vehicle", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP406NOTACCEPTABLE)
    Do $$$AssertEquals(response.ContentType, ##class(%CSP.REST).#CONTENTTYPEJSON)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Do ..Request("GET", "vehicle/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP406NOTACCEPTABLE)
    Do $$$AssertEquals(response.ContentType, ##class(%CSP.REST).#CONTENTTYPEJSON)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = ##class(%CSP.REST).#CONTENTTYPEJSON
    Do ..Request("PUT", "vehicle/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP415UNSUPPORTEDMEDIATYPE)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = ##class(%CSP.REST).#CONTENTTYPEJSON
    Do ..Request("POST", "vehicle", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP415UNSUPPORTEDMEDIATYPE)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = ##class(%CSP.REST).#CONTENTTYPEJSON
    Do ..Request("DELETE", "vehicle/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP415UNSUPPORTEDMEDIATYPE)
    Do $$$AssertEquals(response.ContentType, ##class(%CSP.REST).#CONTENTTYPEJSON)
}

Method TestBad04NoAction()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Do ..Request("GET", "person/1/$promote", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP406NOTACCEPTABLE)
}

Method TestBad05WrongActionMethod()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(%CSP.REST).#CONTENTTYPEJSON
    Set request.ContentType = ##class(%CSP.REST).#CONTENTTYPEJSON
    // Even though string isn't used, write to it to ensure %ToJSON doesn't write to current device
    Set stream = ##class(%Stream.TmpCharacter).%New()
    Set string = {"Zip":"12345"}.%ToJSON(.stream)
    Set request.Content = stream
    Do ..Request("POST", "person/1/$update-home-address", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP405METHODNOTALLOWED)
}

Method TestBad06MalformedJSON()
{
    #dim request As %CSP.Request
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = ##class(%CSP.REST).#CONTENTTYPEJSON
    // No "data"
    Do ..Request("PUT", "person/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP400BADREQUEST)
}

Method TestBad07NoObject()
{
    #dim request As %CSP.Request

    // No person with this ID
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE
    Do ..Request("GET", "person/42000", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP404NOTFOUND)

    // For a PUT it should be 409 Conflict
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = ##class(UnitTest.isc.rest.sample.model.person).#MEDIATYPE
    // Even though string isn't used, write to it to ensure %ToJSON doesn't write to current device
    Set stream = ##class(%Stream.TmpCharacter).%New()
    Set string = {}.%ToJSON(.stream)
    Set request.Content = stream
    Do ..Request("PUT", "person/42000", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP409CONFLICT)
}

Method TestBad08NonJSONTypes()
{
    #dim request As %CSP.Request

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = "application/xml"
    Do ..Request("GET", "person/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP406NOTACCEPTABLE)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = "application/xml"
    // Even though string isn't used, write to it to ensure %ToJSON doesn't write to current device
    Set stream = ##class(%Stream.TmpCharacter).%New()
    Do stream.Write("<foo />")
    Set request.Content = stream
    Do ..Request("PUT", "person/1/$update-home-address", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP415UNSUPPORTEDMEDIATYPE)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = "application/xml"
    Do ..Request("PUT", "person/1/$update-home-address", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP406NOTACCEPTABLE)
}

/// Confirm that the /auth endpoints are not accessible but the
/// /build-documentation and /openapi.json endpoints are supported
Method TestSupportsHandlerEndpoints()
{
    Do ..mockStatic("%pkg.isc.rest.handler", ..#CALLSREALMETHODS)

    #dim request As %CSP.Request

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Do ..Request("GET", "auth/status", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK,"auth/status supported")

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Do ..Request("POST", "auth/logout", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP404NOTFOUND,"auth/logout not supported")

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Do ..when(##class(%pkg.isc.rest.handler).BuildDocumentationEndpoint()).thenReturn($$$OK)
    Do ..Request("POST", "build-documentation", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK,"build-documentation supported")

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Do ..when(##class(%pkg.isc.rest.handler).GetDocumentationBuildStatus()).thenReturn($$$OK)
    Do ..Request("GET", "build-documentation", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK,"build-documentation supported")

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Do ..when(##class(%pkg.isc.rest.handler).GetOpenAPISpecification()).thenReturn($$$OK)
    Do ..Request("GET", "openapi.json", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK,"openapi.json supported")
}

/// Test default code generation of SupportsDefault() for resource class
Method TestSupportsResourceDefault()
{
    #dim request As %CSP.Request

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = "application/json"
    Do ..Request("GET", "empty", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP404NOTFOUND)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = "application/json"
    Do ..Request("POST", "empty", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP404NOTFOUND)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = "application/json"
    Do ..Request("GET", "empty/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP404NOTFOUND)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = "application/json"
    Do ..Request("PUT", "empty/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP404NOTFOUND)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = "application/json"
    Do ..Request("DELETE", "empty/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP404NOTFOUND)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = "application/json"
    Do ..Request("GET", "empty/$new", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP404NOTFOUND)
}

/// Test overridden Supports method.
Method TestSupportsResourceOverridden()
{
    #dim request As %CSP.Request

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = "application/json"
    Do ..Request("GET", "settings", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP200OK)

    // Even though string isn't used, write to it to ensure %ToJSON doesn't write to current device
    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set stream = ##class(%Stream.TmpCharacter).%New()
    Set string = {"timeout": (300)}.%ToJSON(.stream)
    Set request.Content = stream
    Set request.ContentType = "application/json"
    Do ..Request("POST", "settings", .request, .response, .object, .raw)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP201CREATED)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = "application/json"
    Do ..Request("GET", "settings/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP404NOTFOUND)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = "application/json"
    Do ..Request("PUT", "settings/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP404NOTFOUND)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.ContentType = "application/json"
    Do ..Request("DELETE", "settings/1", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP404NOTFOUND)

    Set request = ..mock("%CSP.Request", ..#CALLSREALMETHODS)
    Set request.CgiEnvs("HTTP_ACCEPT") = "application/json"
    Do ..Request("GET", "settings/$new", .request, .response, .object)
    Do $$$AssertEquals(response.Status, ##class(%CSP.REST).#HTTP404NOTFOUND)
}

Method TestOrderMediaTypeList()
{
	#define order(%arg) ##class(%pkg.isc.rest.handler).OrderMediaTypeList(%arg)
	Do $$$LogMessage("Note: $$$order(%arg) is ##class(%pkg.isc.rest.handler).OrderMediaTypeList(%arg)")
	Do $$$AssertEquals($$$order($lb("application/foo+bar.json","*/*")),$lb("application/foo+bar.json","*/*"))
	Do $$$AssertEquals($$$order($lb("*/*","application/foo+bar.json")),$lb("application/foo+bar.json","*/*"))
	Do $$$AssertEquals($$$order($lb("application/*","application/foo+bar.json")),$lb("application/foo+bar.json","application/*"))
	Do $$$AssertEquals($$$order($lb("*/*","application/*")),$lb("application/*","*/*"))
	Do $$$AssertEquals($$$order($lb("application/foo+bar.json","*/*","application/json")),$lb("application/foo+bar.json","application/json","*/*"))
}

}

