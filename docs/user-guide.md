<!-- omit in toc -->
# User Guide for isc.rest

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Create and Configure a REST Handler](#create-and-configure-a-rest-handler)
  - [Define an Authentication Strategy](#define-an-authentication-strategy)
  - [Define a User Resource](#define-a-user-resource)
  - [Authentication-related Endpoints](#authentication-related-endpoints)
  - [Determine REST resources exposed](#determine-rest-resources-exposed)
- [Defining REST Models](#defining-rest-models)
  - [Accessing Data: Adaptor vs. Proxy](#accessing-data-adaptor-vs-proxy)
    - [%pkg.isc.rest.model.adaptor](#pkgiscrestmodeladaptor)
    - [%pkg.isc.rest.model.proxy](#pkgiscrestmodelproxy)
  - [Accessing Complex/Intertwined Data](#accessing-complexintertwined-data)
    - [%pkg.isc.rest.model.resource](#pkgiscrestmodelresource)
    - [%pkg.isc.rest.model.dbMappedResource](#pkgiscrestmodeldbmappedresource)
  - [Permissions](#permissions)
  - [CRUD and Query Endpoints](#crud-and-query-endpoints)
  - [Actions](#actions)
    - [Action Endpoints](#action-endpoints)
  - [Defining Actions](#defining-actions)
  - [Exposing REST Resource in a REST handler](#exposing-rest-resource-in-a-rest-handler)
- [Controlling Endpoints Exposed](#controlling-endpoints-exposed)
- [Public API Surface](#public-api-surface)
- [Known Limitations](#known-limitations)
  - [Actions](#actions-1)
- [Related Topics in InterSystems Documentation](#related-topics-in-intersystems-documentation)

## Introduction

This user guide illustrates instructions to get started with isc.rest 
and the various features of functionality it provides.
For a step-by-step tutorial to see isc.rest in use, see [isc.rest Tutorial and Sample Application: Contact List](sample-phonebook.md).
**NOTE:** Be sure to reference the [Public API Surface](#public-api-surface) to only
use/reference classes listed there. Any class not listed is internal to the package
and could change in backwards incompatible ways without a major semantic version
change.

## Prerequisites

isc.rest requires InterSystems IRIS Data Platform 2018.1 or later.

Installation is done via the [Community Package Manager](https://github.com/intersystems-community/zpm):

```
zpm "install isc.rest"
```

## Getting Started

### Create and Configure a REST Handler

Create a subclass of `%pkg.isc.rest.handler`. This class extends `%CSP.REST`, and
for the most part this subclass may include overrides the same as a subclass of %CSP.REST.

For example, a user may add overrides to use the following %CSP.REST features:

* The `UseSession` class parameter if CSP sessions should be used (by default,
they are not, as CSP sessions are not stateless).
* CORS-related parameters and methods if CORS support is required. (Use this 
carefully and with knowledge of the security implications!)

However, **DO NOT override the UrlMap XData block**; the routes are standardized
and you should not need to edit/amend them.

To augment an existing REST API with isc.rest features, forward a URL from your
existing REST handler to this subclass of `%pkg.isc.rest.handler`.

To create a new isc.rest-based REST API, configure the subclass of `%pkg.isc.rest.handler` 
as the Dispatch Class for a new web application.

### Define an Authentication Strategy

With isc.rest, we ensure security is integrated into REST APIs at 
the outset rather than as an afterthought.

If the web application uses password or delegated authentication, simply override
the AuthenticationStrategy() method in the REST handler class as follows:

```
ClassMethod AuthenticationStrategy() As %Dictionary.Classname
{
    Quit "%pkg.isc.rest.authentication.platformBased"
}
```

If not, create a subclass of `%pkg.isc.rest.authentication` and override the
following methods as appropriate:
- `Authenticate`: Authentication logic to apply to every request to the REST API.
- `UserInfo`: Returns information of the current user to be used in the `/auth/status`
endpoint mentioned [below](#authentication-related-endpoints). This is also passed
as an argument to the various permission checking methods at the handler and
resource class levels.
- `Logout`: Logic to execute during a user logout.
- `CheckPermission`: Permission checks to execute on every request to the REST API
(for all REST resources).

For example, in a more complex token-based approach such as OAuth
that does not use delegated authentication/authorization, `Authenticate` might
check for a bearer token and set `pContinue` to false if one is not present;
`UserInfo` may return an OpenID Connect "userinfo" object; `Logout` may
invalidate/revoke an access token and `CheckPermission` may check for some basic 
scopes required to access the REST API.
In this case, the `AuthenticationStrategy` method in the `%pkg.isc.rest.handler`
subclass should return the name of the class implementing the authentication strategy.

### Define a User Resource

If the application already has a class representing the user model, preferences,
etc., consider providing a REST model for it as described below. Alternatively,
for simple use cases, you may find it helpful to wrap platform security features
in a registered object; see [UnitTest.isc.rest.sample.userContext](../internal/testing/unit_tests/UnitTest/isc/rest/sample/userContext.cls)
for an example of this.

In either approach, the `GetUserResource` method in the application's `%pkg.isc.rest.handler` 
subclass should be overridden to return a new instance of this user model. For example:

```
ClassMethod GetUserResource(pFullUserInfo As %DynamicObject) As UnitTest.isc.rest.sample.userContext
{
    Quit ##class(UnitTest.isc.rest.sample.userContext).%New()
}
```

NOTE: `pFullUserInfo` is the output provided by the `UserInfo()` method
of your authentication strategy class. 

### Authentication-related Endpoints

| HTTP Verb + Endpoint | Function |
| -------------------- | -------- |
| GET /auth/status | Returns information about the currently-logged-in user, if the user is authenticated, or an HTTP 401 if the user is not authenticated and authentication is required. This is the return value from `GetUserResource()` of the application's `%pkg.isc.rest.handler` subclass serialized to JSON. |
| POST /auth/logout | Invokes the authentication strategy's Logout method. (No body expected.) |


### Determine REST resources exposed 

At this point you have a REST handler but no REST resource endpoints.
However, REST resources can only be exposed once they have been created.
The next section details creation of REST resources and the section on
[Exposing REST Resource in a REST handler](#exposing-rest-resource-in-a-rest-handler)
describes how to include it in a REST handler.

<hr>

## Defining REST Models

isc.rest provides for standardized access to both persistent data and business logic.

### Accessing Data: Adaptor vs. Proxy

There are two different approaches to exposing persistent data over REST.
The "Adaptor" approach provides a single REST representation for the existing `%Persistent` class.
The "Proxy" approach provides a REST representation for a *different* `Persistent` class.

#### %pkg.isc.rest.model.adaptor

To expose data of a class that extends %Persistent over REST, simply extend `%pkg.isc.rest.model.adaptor` as well. 
Then, override the following class parameters:

* `RESOURCENAME`: Set this to the URL prefix you want to use for the resource in a REST context (e.g., "person").
* `JSONMAPPING` (optional): Set this to the name of a JSON mapping XData block.
Defaults to empty (the class's default JSON mapping).
Look at [Using XData Mapping Blocks](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GJSON_adaptor#GJSON_adaptor_xdata) to understand how JSON mapping XData blocks work.
* `MEDIATYPE` (optional): May be overridden to specify a different media type 
(e.g., application/vnd.yourcompany.v1+json; must still be an application/json 
subtype or else you will see a compilation error). Defaults to "application/json".
* `IndexToUse` (optional): An alternate unique index to use to identify records
of this class over the [CRUD endpoints](#crud-and-query-endpoints) listed below.
Defaults to "ID" to use the default unique index on row ID of the class.

For an example of using `%pkg.isc.rest.model.adaptor`, see:
[UnitTest.isc.rest.sample.data.vendor](../internal/testing/unit_tests/UnitTest/isc/rest/sample/data/vendor.cls)

#### %pkg.isc.rest.model.proxy

To expose data of a *different* class that extends %Persistent over REST, perhaps 
using an alternative JSON mapping from other projections of the same data, 
extend `%pkg.isc.rest.model.proxy`.
In addition to the same parameters as `%pkg.isc.rest.model.adaptor`, you must also 
override the `SOURCECLASS` parameter to specify a different class that extends 
both `%pkg.isc.json.adaptor` and `%Persistent`.

For an example of using `%pkg.isc.rest.model.proxy`, see:
[UnitTest.isc.rest.sample.model.person](../internal/testing/unit_tests/UnitTest/isc/rest/sample/model/person.cls)

### Accessing Complex/Intertwined Data

#### %pkg.isc.rest.model.resource

To expose data that either cannot be mapped nicely to a single persistent class or
in the case that you want to provide a view across several persistent classes,
extend `%pkg.isc.rest.model.resource`.
Then you must override the `RESOURCENAME` parameter as well as any abstract methods you wish to implement.

For an example of using `%pkg.isc.rest.model.resource`, see: 
[UnitTest.isc.rest.sample.model.person](../internal/testing/unit_tests/UnitTest/isc/rest/sample/model/settings.cls)

#### %pkg.isc.rest.model.dbMappedResource

To expose data that maps to a single %Persistent class, involving significant augmentation or cutting of the JSON that would normally be returned in the response if the %Persistent class were extending `%pkg.isc.rest.model.adaptor`, extend `%pkg.isc.rest.model.dbMappedResource` and overwrite the GeModelFromObject method to populate properties.  

### Permissions

Using any of the above approaches for accessing/exposing data, all endpoints for 
accessing the data are protected via the `CheckPermission()` method.
Irrespective of which `%pkg.isc.rest.model.*` class above you extend, you must 
override the `CheckPermission()` method, which by default says that nothing is allowed:

```
/// Checks the user's permission for a particular operation on a particular record.
/// <var>pOperation</var> may be one of the macros of the form $$$Operation*
/// present in %pkg.isc.rest.general.inc. <br />
/// If this method returns 0, the corresponding dispatch class will return a 403
/// Unauthorized status when the operation is invoked. <br />
/// <var>pUserContext</var> is supplied by <method>GetUserContext</method>. <br />
ClassMethod CheckPermission(pID As %String, pOperation As %String, pUserContext As %RegisteredObject) As %Boolean
{
    Quit 0
}
```

`pUserContext` is an instance of the [user resource defined earlier](#define-a-user-resource).

Implement this method with any security checks you want for your REST resource.

### CRUD and Query Endpoints

With resources defined as described above, the following endpoints are available:

| HTTP Verb + Endpoint | Function |
| -------------------- | -------- |
| GET `/:resource` | Returns an array of instances of the requested resource, subject to filtering criteria specified by URL query parameters. |
| POST `/:resource` | Saves a new instance of the specified resource (present in the request entity body) in the database. Responds with the JSON representation of the resource, as well as any fields populated when the record was saved. |
| GET `/:resource/:id` | Retrieves an instance of the resource with the specified ID. |
| PUT `/:resource/:id` | Updates the specified instance of the resource in the database (based on ID, with the data present in the request entity body). Responds with the JSON representation of the resource, including any fields updated when the record was saved.​ |
| DELETE `/:resource/:id` | Deletes the instance of the resource with the specified ID. |

NOTE: If using the default index of ID, you may want to override the `%JSONINCLUDEID`
parameter in the persistent class to set it to 1 so that you have the ID available
from GET/POST requests without an ID to send back for GET/PUT/DELETE requests 
which require an ID.

### Actions

"Actions" allow you to provide a REST projection of business logic (that is,
ObjectScript methods and classmethods) and class queries (abstractions of more
complex SQL) alongside the basic REST capabilities.
To start, override the `Actions` XData block:

```
XData ActionMap [ XMLNamespace = "http://www.intersystems.com/_pkg/isc/rest/action" ]
{
}
```

NOTE: Studio/VS Code will help with code completion for XML in this namespace.

[UnitTest.isc.rest.sample.model.person](../internal/testing/unit_tests/UnitTest/isc/rest/sample/model/person.cls) has annotated examples covering the full range of action capabilities.
As a general guideline, do ensure that the HTTP verb matches the behavior of the
endpoint (e.g., PUT and DELETE are idempotent, GET is safe, POST is neither).

#### Action Endpoints

| HTTP Verbs + Endpoint | Function |
| --------------------- | -------- |
| GET,PUT,POST,PATCH,DELETE `/:resource/$:action` | Performs the named action on the specified resource. Constraints and format of URL parameters, body, and response contents will vary from action to action, but are well-defined via the ActionMap XData block. |
| GET,PUT,POST,PATCH,DELETE `/:resource/:id/$:action` | Performs the named action on the specified resource instance. Constraints and format of URL parameters, body, and response contents will vary from action to action, but are well-defined via the ActionMap XData block. |

### Defining Actions

Within the ActionMap XData block, Actions are defined like this:

```XML
<actions>
<action name="my-action" target="class" call="MyMethod">
	<argument name="myURLparam" target="param" source="query"/>
</action>
</actions>
```

The following options, as defined in `%pkg.isc.rest.model.action.t.action`, may be included as xml attributes for each action:

| Action Attribute | Function |
| ------- | -------- |
| name | Required. Name of the action, used in URLs. |
| target | "class" or "instance." Determines whether the action targets the class or an instance of the class. Defaults to "class". Required if query is not defined. |
| method | The HTTP method to use for the action. Defaults to POST, as this will be most common. | 
| call | The name of a class/instance method this action should call. May take the format <code>classname:methodname</code> if in a different class. Either *call* or *query* must be defined. |
| query |  The class query this action should run. May take the form <code>classname:queryname</code> if in a different class. Either *call* or *query* must be defined. |
| modelClass | For queries, the model class used to project results returned by the query, if different from the source class. |

Each action may include zero or more ```<argument>``` elements, in order to pass variables to its called method or query, as defined in `%pkg.isc.rest.model.action.t.argument`. Each argument element may include the following options as xml attributes:

| Argument Attribute | Function |
| ------------------ | -------- |
| name | Name of the parameter (used in URLs). Required for source types *form-data*, *query*, and *path.* | 
| required | Is this argument required (if missing, treat as client error). 1 or 0, defaults to 0 |
| target | Required. Name of target argument in method or query definition. |
| source | Source from the request to pass to the target argument. Options are: body, body-key, form-data, query, path, id, and user-context.  See table below for further details. |


| Argument Source Type | Value Passed to Target Argument |
| ----------- | -------- |
| body | The entire body content. Can have AT MOST ONE argument with this source. If the target argument type is an instance of `%pkg.isc.rest.model.resource` or is %JSONENABLED, an instance of that class will be created from the body content before passing it as an argument to the corresponding method or class query for the action. See update-home-address in [UnitTest.isc.rest.sample.model.person](../internal/testing/unit_tests/UnitTest/isc/rest/sample/model/person.cls). | 
| body-key | A single key from a JSON body. | 
| form-data | Multi-part form data, e.g. processing an uploaded file. | 
| query  | A query parameter in the URL. See find-by-phone in [isc.sample.rest.phonebook.model.Person](../samples/phonebook/cls/isc/sample/rest/phonebook/model/Person.cls). | 
| path  | A path parameter from the URL for actions with target = "instance". MUST also be present with a colon in the URL, matching the same name e.g. if the URL path for the action is `/example/:ex`, then the argument name MUST be `ex`. See path-param in [UnitTest.isc.rest.sample.model.person](../internal/testing/unit_tests/UnitTest/isc/rest/sample/model/person.cls). | 
| id  | Resource id from the URL for actions with target = "instance". See update-home-address in [UnitTest.isc.rest.sample.model.person](../internal/testing/unit_tests/UnitTest/isc/rest/sample/model/person.cls). | 
| user-context | Logged-in user as defined by [GetUserResource](#define-a-user-resource) in subclasses of ```%pkg.isc.rest.handler``` |

### Exposing REST Resource in a REST handler

Now that a REST resource class has been created (i.e. a class extending a `%pkg.isc.rest.model.*` class),
you may want to expose it in a specific REST handler.
To do so, override the `CheckResourcePermitted()` method in your subclass of `%pkg.isc.rest.handler`.
This method takes a resource class name as an argument and returns a boolean value 
indicating whether that resource class should be exposed as a part of the REST handler.

A REST resource class can be exposed in multiple REST handlers.

NOTE: `CheckResourcePermitted()` is invoked at compilation time to tie REST resource 
classes to their corresponding REST handler classes so no runtime logic should be 
present here.

An example is present in [UnitTest.isc.rest.sample.handler](../internal/testing/unit_tests/UnitTest/isc/rest/sample/handler.cls).

## Controlling Endpoints Exposed

While `CheckResourcePermitted()` mentioned in the above [section](#exposing-rest-resource-in-a-rest-handler)
only allows for compile time checks to determine whether a REST resource is exposed 
as part of a REST handler, there are also runtime hooks available.

The following sets of endpoints are exposed in a REST handler:
- [Authentication Related Endpoints](#authentication-related-endpoints)
- [CRUD and Query Endpoints](#crud-and-query-endpoints)
- [Action Endpoints](#action-endpoints)

The first of those can be restricted via overriding the `Supports()` method in your 
REST handler class i.e. a subclass of `%pkg.isc.rest.handler`.
Here is the method signature:

```
/// Checks if the endpoint provided is supported for the current dispatch class.
/// If the method returns 0 for a given endpoint, requests to the endpoint will
/// get a 404 and the endpoint will be excluded from the Open API specification. <br />
/// Default behavior is to return 1 for all endpoints. <br />
/// <var>pEndpoint</var> can be one of the endpoint-http verb combinations present
/// in <parameter>SupportsCheckEndpoints</parameter>. <br />
/// <var>pHTTPVerb</var> is the HTTP verb for the endpoint. <br />
/// <var>pRequest</var> is the request object in an HTTP context. <br />
ClassMethod Supports(
	pEndpoint As %String,
	pHTTPVerb As %String,
	pRequest As %CSP.Request = {$$$NULLOREF}) As %Boolean
{
	Return 1
}
```

This method can be implemented to remove authentication related endpoints from 
the REST handler by returning 0 for those endpoints i.e. attempts to access the
endpoints will result in a 404 HTTP status code.

For the second and third sets of endpoints, an equivalent `Supports()` method can 
be overridden in your subclass of any `%pkg.isc.rest.model.*` class.
Here is the default implementation of the method in `%pkg.isc.rest.model.resource`:

```
/// Checks if the particular operation is supported for this resource. <br />
/// Look at documentation of <method>SupportsDefault</method> for default behavior
/// of this method. <br />
/// If the method returns 0, the corresponding dispatch class will return a 404
/// Not Found status when the operation is invoked. <br />
/// NOTE: This method runs on EVERY request so should be quick, lightweight checks
/// to prevent performance bottlenecks. <br />
/// <var>pOperation</var> may be one of the macros of the form $$$Operation*
/// present in %pkg.isc.rest.general.inc. <br />
/// <var>pType</var> is the type of the operation (instance-level on a particular
/// record or class-level). <br />
/// <var>pRequest</var> is the request object in an HTTP context.
/// NOTE: MUST check that this is an object before using it as it may be passed
/// as a NULL OREF in some cases. <br />
ClassMethod Supports(
	pOperation As %String,
	pType As %String(VALUELIST=",instance,class"),
	pRequest As %CSP.Request = {$$$NULLOREF}) As %Boolean
{
	Return ..SupportsDefault(pOperation, pType)
}
```

Similar to the prior `Supports()` method at the REST handler level, whenever this 
method returns 0 for a given endpoint, the endpoint is removed from the REST handler 
i.e. attempts to access the endpoints will result in a 404 HTTP status code.

## Public API Surface

Only the following classes should directly be used by consuming applications i.e.
extending the classes/creating instances of classes/invoking methods or queries 
on the classes:
- `%pkg.isc.rest.handler`
- `%pkg.isc.rest.authentication`
- `%pkg.isc.rest.authentication.*`
- `%pkg.isc.rest.model.resource`
- `%pkg.isc.rest.model.iSerializable`
- `%pkg.isc.rest.model.proxy`
- `%pkg.isc.rest.model.adaptor`
- `%pkg.isc.rest.model.dbMappedResource`
- `%pkg.isc.rest.openAPI.model.*`

Only the following include files should be directly used by consuming applications:
- `%pkg.isc.rest.general`

## Known Limitations

### Actions

- Actions only support the following return types as of now (i.e. any instance/class
methods that are invoked as part of the ActionMap XData block):
  - `%Status`
  - `%DynamicAbstractObject` and its subclasses
  - Any JSON serializable class i.e. one that extends either `%pkg.isc.json.adaptor` and `%JSON.Adaptor`
- You cannot select which JSON mapping of a JSON serializable class to use when
projecting it to JSON.

## Related Topics in InterSystems Documentation

* [Using the JSON Adaptor](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GJSON_adaptor)
* [Introduction to Creating REST Services](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GREST_intro)
* [Supporting CORS in REST Services](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GREST_cors)
* [Securing REST Services](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GREST_securing)
