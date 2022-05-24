ROUTINE %pkg.isc.rest.general [Type=INC]

/// Contains whitelisted classes for which isc.rest auditing is ignored.
#define ConfigWhiteListGbl(%pClass) ^Config("%pkg.isc.rest","WhiteList",%pClass)
/// Wrapper to call the %ClassName method on a given class
#define CLASSNAME(%name) $classmethod(%name, "%ClassName", 1)
#def1arg RESTErrorLogConfigGbl(%handlerClass) ^Config("%pkg.isc.rest","LogLevel",%handlerClass)