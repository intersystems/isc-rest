ROUTINE %pkg.isc.rest.general [Type=INC]

/// Contains whitelisted classes for which isc.rest auditing is ignored.
#define ConfigWhiteListGbl(%pClass) ^Config("%pkg.isc.rest","WhiteList",%pClass)
/// Wrapper to call the %ClassName method on a given class
#define CLASSNAME(%name) $classmethod(%name, "%ClassName", 1)
#def1arg RESTErrorLogConfigGbl(%handlerClass) ^Config("%pkg.isc.rest","LogLevel",%handlerClass)

#; Operations allowed on REST resources

/// Operation to create a REST resource
#define OperationCreate             "CREATE"
/// Operation to read a REST resource
#define OperationRead               "READ"
/// Operation to update a REST resource
#define OperationUpdate             "UPDATE"
/// Operation to delete a REST resource
#define OperationDelete             "DELETE"
/// Operation to query a REST resource
#define OperationQuery              "QUERY"
/// Operation to perform a custom action with the provided name on a REST resource
#define OperationAction(%action)    "ACTION:"_%action
/// Operation to perform the special "new" action on a REST resource
#define OperationActionNew          $$$OperationAction("new")

#; Operation types allowed on REST resources

/// Class-level operation on a REST resource
#define TypeOperationClass "class"
/// Instance-level operation on a REST resource
#define TypeOperationInstance "instance"
