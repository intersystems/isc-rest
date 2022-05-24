Class %pkg.isc.rest.model.paginatedQueryResult Extends %pkg.isc.rest.model.queryResult
{

Property Done As %Boolean;

ClassMethod FromClassQuery(pModelClass As %Dictionary.CacheClassname, pQueryClass As %Dictionary.CacheClassname, pQueryName As %Dictionary.CacheIdentifier, pLimit = "", pOffset = 0, pArgs...) As %pkg.isc.rest.model.paginatedQueryResult
{
	Set result = ##class(%Library.ResultSet).%New(pQueryClass_":"_pQueryName)
	Quit ..FromResultSet(pModelClass, result, pLimit, pOffset, pArgs...)
}

ClassMethod FromResultSet(pModelClass As %Dictionary.CacheClassname, pResultSet As %Library.ResultSet, pLimit = "", pOffset = 0, pArgs...) As %pkg.isc.rest.model.paginatedQueryResult
{
	Set instance = ..%New()
	$$$ThrowOnError(pResultSet.%Execute(pArgs...))
	If (pResultSet.%SQLCODE < 0) {
		Throw ##class(%Exception.SQL).CreateFromSQLCODE(pResultSet.%SQLCODE,pResultSet.%Message)
	}
	Set useResult = +$Parameter(pModelClass,"ConstructFromResultRow")
	set idx = 0
	set instance.Done = 1
	While pResultSet.%Next(.sc) {
		if ((pOffset '= "") && (idx < pOffset)) {
		} elseif ((pLimit '= "") && (pLimit + pOffset = idx)) {
			set instance.Done = 0
			quit
		} else {
			$$$ThrowOnError(sc)
			Set resource = $classmethod(pModelClass,"GetModelInstance",$Select(useResult:pResultSet,1:pResultSet.%GetData(1)))
			If $IsObject(resource) {
				Do instance.rows.Insert(resource)
			}
		}
		set idx = idx + 1
	}
	$$$ThrowOnError(sc)
	Quit instance
}

}

