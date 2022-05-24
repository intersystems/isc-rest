Include %syGluedef

Class UnitTest.isc.rest.handler.errorLogging Extends HSTools.UnitTest.Mock.TestCase
{

Method TestExternalInterrupt()
{
	New %response,%request
	Set %response = ..mock("%CSP.Response")
	Set %request = ..mock("%CSP.Request")

	Do ##class(%pkg.isc.rest.handler).SetLogLevel(2)
	
	Set oldErrorCount = +$Get(^ERRORS(+$Horolog))
	Set sc = $$$ERROR($$$CacheError,"<EXTERNAL INTERRUPT>",$$$EREXTINT)
	Do ##class(%pkg.isc.rest.handler).ReportHttpStatusCode(##class(%CSP.REST).#HTTP500INTERNALSERVERERROR,sc)
	Do $$$AssertEquals(oldErrorCount,+$Get(^ERRORS(+$Horolog)),"No new errors logged.")
}

Method TestDefaultLogging()
{
	New %response,%request
	Set %response = ..mock("%CSP.Response")
	Set %request = ..mock("%CSP.Request")

	Do ##class(%pkg.isc.rest.handler).SetLogLevel()
	
	Set oldErrorCount = +$Get(^ERRORS(+$Horolog))
	Set sc = $$$ERROR($$$CacheError,"<SUBSCRIPT>",$$$ERSSVNSUB)
	Do ##class(%pkg.isc.rest.handler).ReportHttpStatusCode(##class(%CSP.REST).#HTTP500INTERNALSERVERERROR,sc)
	Do $$$AssertEquals(oldErrorCount,+$Get(^ERRORS(+$Horolog)),"No new errors logged.")
}

Method TestLoggingEnabled()
{
	New %response,%request
	Set %response = ..mock("%CSP.Response")
	Set %request = ..mock("%CSP.Request")

	Do ##class(%pkg.isc.rest.handler).SetLogLevel(2)
	
	Set oldErrorCount = +$Get(^ERRORS(+$Horolog))
	Set sc = $$$ERROR($$$CacheError,"<SUBSCRIPT>",$$$ERSSVNSUB)
	Do ##class(%pkg.isc.rest.handler).ReportHttpStatusCode(##class(%CSP.REST).#HTTP500INTERNALSERVERERROR,sc)
	Do $$$AssertEquals(oldErrorCount+1,+$Get(^ERRORS(+$Horolog)),"One new error logged.")
}

}

