Class UnitTest.isc.rest.angularHandler Extends (HSTools.UnitTest.Mock.TestCase, %UnitTest.TestCase)
{

Method TestIndexHTMLPaths()
{
	Do ..SetUpMock()
	Do $$$AssertEquals(..GetFileServed(""),"/index.html")
	Do $$$AssertEquals(..GetFileServed("home"),"/index.html")
	Do $$$AssertEquals(..GetFileServed("view/record"),"/index.html")
}

Method TestNonHTMLPaths()
{
	Do ..SetUpMock()
	Do $$$AssertEquals(..GetFileServed("assets/foo.jpg"),"/assets/foo.jpg")
	Do $$$AssertEquals(..GetFileServed("foo.js"),"/foo.js")
	Do $$$AssertEquals(..GetFileServed("foo.map"),"/foo.map")
	Do $$$AssertEquals(..GetFileServed("foo.woff"),"/foo.woff")
	Do $$$AssertEquals(..GetFileServed("foo.woff2"),"/foo.woff2")
}

Method SetUpMock()
{
	Do ..mockStatic("%CSP.StreamServer")
	Do ..when(##class(%CSP.StreamServer).Page()).thenReturn($$$OK)
}

Method GetFileServed(path) As %String
{
	New %request, %response
	Set %request = ..mock("%CSP.Request",..#CALLSREALMETHODS)
	set %response = ..mock("%CSP.Response", ..#CALLSREALMETHODS)
	Set %request.Application = "/"
	Do ##class(%pkg.isc.rest.angularHandler).ServeStaticFile(path)
	if ((path [ "woff") || (path [ "assets")){
		do ..verify(%response.SetHeader("cache-control", ..anyString()))
	}
	else { 
		do ..verify(%response.SetHeader("cache-control", ..anyString()), ..times(0))
	}
	Quit %request.Get("FILE")
}

}

