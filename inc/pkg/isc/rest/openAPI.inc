ROUTINE %pkg.isc.rest.openAPI [Type=INC]

#; Timing

#define TimerNow ($ZDateTime($Now(),-2)_"."_$Piece($Now(),".",*))
#define TimerMSSince(%startTime) (($$$TimerNow - %startTime)*1000)
#define TimerStart Set timer = $$$TimerNow
#define TimerEnd Set ws = 0 Write:..DEBUG *27,"[58mSub-section execution time: " _ $$$TimerMSSince(timer) _ "ms",*27,"[0m",! $$$TimerStart

#; Globals

#define DocLocksBuildGbl ^pkg.isc.rest.documentation.locks("Build")

#define DocTimingBuildStartGbl ^pkg.isc.rest.documentation.timing("Build","Start")
#define DocTimingBuildFinishGbl ^pkg.isc.rest.documentation.timing("Build","Finish")

#define DocParameterBuildDebugGbl ^pkg.isc.rest.documentation.parameters("Build","debug")
#define DocParameterBuildInternalGbl ^pkg.isc.rest.documentation.parameters("Build","internal")
#define DocParameterBuildUserGbl ^pkg.isc.rest.documentation.parameters("Build","userContext")
#define DocParameterBuildUserVerboseGbl ^pkg.isc.rest.documentation.parameters("Build","userContext","verbose")

#define DocStageBuildOpenAPIGbl ^pkg.isc.rest.documentation.stage("Build","OpenAPI")
#define DocStageBuildDocTypeGbl(%docType) ^pkg.isc.rest.documentation.stage("Build",%docType)
