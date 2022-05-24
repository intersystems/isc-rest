Class UnitTest.isc.rest.openAPI.testCase Extends %UnitTest.TestCase
{

Property ClassTracker As array Of %Boolean;

Property TransactionLevel As %Integer;

Parameter RunInTransaction As BOOLEAN = 1;

Method OnBeforeAllTests() As %Status
{
	if ..#RunInTransaction {
		Set ..TransactionLevel = $TLevel
		TStart
	}
	Return ##super()
}

Method OnAfterAllTests() As %Status
{
	Set classname = ""
	Do ..ClassTracker.GetNext(.classname)
	While classname '= "" {
		Do ..TeardownClass(classname)
		Do ..ClassTracker.GetNext(.classname)
	}
	if ..#RunInTransaction {
		While $TLevel > ..TransactionLevel { TRollback 1 }
	}
	Return ##super()
}

/// Ensure we start from a clean slate on each test
Method OnBeforeOneTest(testname As %String) As %Status
{
	Quit $System.OBJ.DeletePackage("zUnitTest.isc.rest","-d")
}

Method SetupClass(className, classSupers As %DynamicArray = "", classParameters As %DynamicObject = "", propertyName = "", propertyFields As %DynamicObject = "", propertyParameters As %DynamicObject = "", relationshipName = "", relationshipFields As %DynamicObject = "", relationshipParameters As %DynamicObject = "", cloneXDatas As %DynamicArray = "", cloneMethods As %DynamicArray = "", cloneQueries As %DynamicArray = "", classDescription = "") As %Status
{
	#define JSONAdaptor ##class(UnitTest.isc.rest.openAPI.compatibility).GetJSONAdaptorClass()
	#define JSONMapping ##class(UnitTest.isc.rest.openAPI.compatibility).GetJSONMappingClass()
	#define JSONBoolean ##class(UnitTest.isc.rest.openAPI.compatibility).GetBooleanClass()

	Set classobj = ##class(%Dictionary.ClassDefinition).%OpenId(className)
	Set:'$IsObject(classobj) classobj = ##class(%Dictionary.ClassDefinition).%New()
	Do ..ClassTracker.SetAt(1, className)
	Set classobj.Name = className
	set classobj.Description = classDescription
	If $IsObject(classSupers) {
		Set supersIterator = classSupers.%GetIterator()
		While supersIterator.%GetNext(,.super) {
			If '$Data(supersList) {
				Set supersList = $ListBuild(super)
			} Else {
				Set $List(supersList, $ListLength(supersList)+1) = super
			}
		}
		Set classobj.Super = $ListToString(supersList, ",")
	}
	Set sc = classobj.%Save()
	Return:$System.Status.IsError(sc) sc 
	If $IsObject(classParameters) {
		Set parametersIterator = classParameters.%GetIterator()
		While parametersIterator.%GetNext(.paramName, .paramValue) {
			Set param = ##class(%Dictionary.ParameterDefinition).%OpenId(className _ "||" _ paramName)
			If $IsObject(param) {
				Set param.Default = paramValue
				Do param.%Save()
			} Else {
				Set param = ##class(%Dictionary.ParameterDefinition).%New()
				Set param.Name = paramName
				Set param.Default = paramValue
				Do classobj.Parameters.Insert(param)
			}
		}
	}
	If propertyName '= "" {
		Set property = ##class(%Dictionary.PropertyDefinition).%New()
		If $IsObject(propertyFields) {
			Set fieldsIterator = propertyFields.%GetIterator()
			While fieldsIterator.%GetNext(.fieldName, .fieldValue) {
				Set $Property(property, fieldName) = fieldValue
			}
		}
		If $IsObject(propertyParameters) {
			Set parametersIterator = propertyParameters.%GetIterator()
			While parametersIterator.%GetNext(.paramName, .paramValue) {
				Do property.Parameters.SetAt(paramValue, paramName)
			}
		}
		Set property.Name = propertyName
		Do classobj.Properties.Insert(property)
	}
	If relationshipName '= "" {
		Set relationship = ##class(%Dictionary.PropertyDefinition).%New()
		Set relationship.Relationship = 1
		If $IsObject(relationshipFields) {
			Set fieldsIterator = relationshipFields.%GetIterator()
			While fieldsIterator.%GetNext(.fieldName, .fieldValue) {
				Set $Property(relationship, fieldName) = fieldValue
			}
		}
		If $IsObject(relationshipParameters) {
			Set parametersIterator = relationshipParameters.%GetIterator()
			While parametersIterator.%GetNext(.paramName, .paramValue) {
				Do relationship.Parameters.SetAt(paramValue, paramName)
			}
		}
		Set relationship.Name = relationshipName
		Do classobj.Properties.Insert(relationship)
	}
	If $IsObject(cloneXDatas) {
		Set xdataIterator = cloneXDatas.%GetIterator()
		While xdataIterator.%GetNext(,.xdataLocation) {
			Set xdataName = $Piece(xdataLocation, ":", *)
			Set xdataSource = $Piece(xdataLocation, ":", 1)
			Set xdata = ##class(%Dictionary.XDataDefinition).%OpenId($ClassName($This)_"||"_xdataSource).%ConstructClone(1)
			Set xdata.Name = xdataName
			If xdata.XMLNamespace = "http://www.intersystems.com/jsonmapping" {
				Set jsonMappingNS = $parameter($$$JSONMapping,"NAMESPACE")
				if (jsonMappingNS '= xdata.XMLNamespace) {
					Set xdata.XMLNamespace = jsonMappingNS
					Set data = $Replace(xdata.Data.Read(),"http://www.intersystems.com/jsonmapping",jsonMappingNS)
					$$$ThrowOnError(xdata.Data.Clear())
					$$$ThrowOnError(xdata.Data.Write(data))
				}
			}
			Do classobj.XDatas.Insert(xdata)
		}
	}
	If $IsObject(cloneMethods) {
		Set methodIterator = cloneMethods.%GetIterator()
		While methodIterator.%GetNext(,.methodLocation) {
			Set methodName = $Piece(methodLocation, ":", *)
			Set methodSource = $Piece(methodLocation, ":", 1)
			Set method = ##class(%Dictionary.MethodDefinition).%OpenId($ClassName($This)_"||"_methodSource).%ConstructClone(1)
			Set method.Name = methodName
			Do classobj.Methods.Insert(method)
		}
	}
	If $IsObject(cloneQueries) {
		Set queryIterator = cloneQueries.%GetIterator()
		While queryIterator.%GetNext(,.queryLocation) {
			Set queryName = $Piece(queryLocation, ":", *)
			Set querySource = $Piece(queryLocation, ":", 1)
			Set query = ##class(%Dictionary.QueryDefinition).%OpenId($ClassName($This)_"||"_querySource).%ConstructClone(1)
			Set query.Name = queryName
			Do classobj.Queries.Insert(query)
		}
	}
	Set sc = classobj.%Save()
	Do:$system.Status.IsError(sc) $$$LogMessage("*** Class setup failed, this may be because another test failed before this one ran ***")
	Return sc
}

Method TeardownClass(className) As %Boolean
{
	#dim ex As %Exception.AbstractException
	Try {
		If ..ClassTracker.GetAt(className) = 1 {
			Do ..ClassTracker.SetAt(0, className)
			Set classActionsName = className_".Actions"
			&sql(DELETE from %pkg_isc_rest.resourceMap WHERE ResourceClass = :className)
			&sql(DELETE from %pkg_isc_rest.actionMap WHERE ResourceClass = :className OR ImplementationClass = :classActionsName)
			Return $system.OBJ.Delete(className, "-d/deleteextent")
		}
	} Catch ex {
		Write !, ex.DisplayString()
		Return 0
	}
	Return 0
}

Method CompileClass(className) As %Status
{
	Return $System.OBJ.Compile(className,"bckry-d")
}

Method CompileClassList(ByRef classList) As %Status
{
	Return $System.OBJ.CompileList(.classList,"bckry-d")
}

Method VerifyJSON(obj, sub, err, assert = 1) As %Boolean
{
	If sub = obj {
		Do:assert $$$AssertTrue(1, err)
		Return 1
	}
	Set iterator = sub.%GetIterator()
	While iterator.%GetNext(.subname, .subvalue) {
		If 'obj.%IsDefined(subname) {
			Do:assert $$$AssertTrue(0, err _ "[" _ subname _ "] is missing")
			Return 0
		}
		If $ClassName(subvalue) = "%Library.DynamicObject" {
			Return:'..VerifyJSON(obj.%Get(subname), subvalue, err _ "[" _ subname _ "]") 0
		} ElseIf $ClassName(subvalue) = "%Library.DynamicArray" {
			Set iterator2 = subvalue.%GetIterator()
			While iterator2.%GetNext(.subname2, .subvalue2) {
				Set found = 0
				Set iterator3 = obj.%Get(subname).%GetIterator()
				While iterator3.%GetNext(.objname, .objvalue) {
					If ..VerifyJSON(objvalue,subvalue2,"",0) {
						Set found = 1
						Quit
					}
				}
				If 'found {
					Do:assert $$$AssertTrue(0, err _ "[" _ subname _ ":" _ subname2 _ "] missing value " _ subvalue2)
					Return 0
				}
			}
		} Else {
			If obj.%Get(subname)'=subvalue {
				Do:assert $$$AssertTrue(0, err _ "[" _ subname _ "] was " _ obj.%Get(subname) _ " expected " _ subvalue)
				Return 0
			}
		}
	}
	Do:assert $$$AssertTrue(1, err)
	Return 1
}

}

