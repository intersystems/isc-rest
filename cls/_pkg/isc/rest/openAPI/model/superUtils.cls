Class %pkg.isc.rest.openAPI.model.superUtils
{

ClassMethod Extends(mainClass As %String, possibleSuperclass As %String) As %Boolean [ Internal ]
{
		Return ..ExtendsInternal(mainClass, possibleSuperclass, .temp)
}

ClassMethod ExtendsInternal(mainClass As %String, possibleSuperclass As %String, ByRef visited) As %Boolean [ Internal ]
{
		Set visited(mainClass) = ""
		If mainClass = possibleSuperclass {
			Return 1
		}
		Set supersList = $ListFromString(##class(%Library.ClassDefinition).%OpenId(mainClass).Super, ",")
		If $ListFind(supersList, possibleSuperclass) {
			Return 1
		} Else {
			For i=1:1:$ListLength(supersList) {
				Set superClass = $ListGet(supersList, i)
				If '($Data(visited(superClass))#2) && ..ExtendsInternal(superClass, possibleSuperclass) {
					Return 1
				}
			}
		}
		Return 0
}

}

