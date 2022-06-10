<!-- omit in toc -->
# User Guide for isc.rest

- [Introduction](#introduction)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Create and Configure a REST Handler](#create-and-configure-a-rest-handler)
  - [Define an Authentication Strategy](#define-an-authentication-strategy)
  - [Define a User Resource](#define-a-user-resource)
  - [Authentication-related Endpoints](#authentication-related-endpoints)
- [Defining REST Models](#defining-rest-models)
  - [Accessing Data: Adaptor vs. Proxy](#accessing-data-adaptor-vs-proxy)
    - [%pkg.isc.rest.model.adaptor](#pkgiscrestmodeladaptor)
    - [%pkg.isc.rest.model.proxy](#pkgiscrestmodelproxy)
  - [Accessing Complex/Intertwined Data](#accessing-complexintertwined-data)
  - [Permissions](#permissions)
  - [CRUD and Query Endpoints](#crud-and-query-endpoints)
  - [Actions](#actions)
    - [Action Endpoints](#action-endpoints)
  - [Defining a Custom Resource](#defining-a-custom-resource)
- [Controlling Endpoints Exposed](#controlling-endpoints-exposed)
- [Public API Surface](#public-api-surface)
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
In this case, the `AuthenticationStrategy` method in the `%pkg.isc.rest.handler` subclass should return the name of the class implementing the authentication strategy.

### Define a User Resource

If the application already has a class representing the user model, preferences,
etc., consider providing a REST model for it as described below. Alternatively,
for simple use cases, you may find it helpful to wrap platform security features
in a registered object; see [UnitTest.isc.rest.sample.userContext](../internal/testing/unit_tests/UnitTest/isc/rest/sample/userContext.cls)
for an example of this.

In either approach, the `GetUserResource` method in the application's `%pkg.isc.rest.handler` subclass should be overridden to return a new instance of this user model. For example:

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

<hr>

## Defining REST Models

isc.rest provides for standardized access to both persistent data and business logic.

### Accessing Data: Adaptor vs. Proxy

There are two different approaches to exposing persistent data over REST. The "Adaptor" approach provides a single REST representation for the existing `%Persistent` class. The "Proxy" approach provides a REST representation for a *different* `Persistent` class.

#### %pkg.isc.rest.model.adaptor

To expose data of a class that extends %Persistent over REST, simply extend `%pkg.isc.rest.model.adaptor` as well. Then, override the following class parameters:

* `RESOURCENAME`: Set this to the URL prefix you want to use for the resource in a REST context (e.g., "person").
* `JSONMAPPING` (optional): Set this to the name of a JSON mapping XData block. Defaults to empty (the class's default JSON mapping). Look at [Using XData Mapping Blocks](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GJSON_adaptor#GJSON_adaptor_xdata)
to understand how JSON mapping XData blocks work.
* `MEDIATYPE` (optional): May be overridden to
specify a different media type (e.g., application/vnd.yourcompany.v1+json;
must still be an application/json subtype or else you will see a compilation error).
Defaults to "application/json".
* `IndexToUse` (optional): An alternate unique index to use to identify records
of this class over the [CRUD endpoints](#crud-and-query-endpoints) listed below.
Defaults to "ID" to use the default unique index on row ID of the class.

For an example of using `%pkg.isc.rest.model.adaptor`, see:
[UnitTest.isc.rest.sample.data.vendor](../internal/testing/unit_tests/UnitTest/isc/rest/sample/data/vendor.cls)

#### %pkg.isc.rest.model.proxy

To expose data of a *different* class that extends %Persistent over REST, perhaps using an alternative JSON mapping from other projections of the same data, extend `%pkg.isc.rest.model.proxy`. In addition to the same parameters as `%pkg.isc.rest.model.adaptor`, you must also override the `SOURCECLASS` parameter to specify a different class that extends both `%pkg.isc.json.adaptor` and `%Persistent`.

For an example of using `%pkg.isc.rest.model.proxy`, see:
[UnitTest.isc.rest.sample.model.person](https://github.com/intersystems/isc-rest/blob/master/internal/testing/unit_tests/UnitTest/isc/rest/sample/model/person.cls)

### Accessing Complex/Intertwined Data

#### %pk.isc.rest.model.resource

To expose data that either cannot be mapped nicely to a single persistent class or in the case that you want to provide a view across several persistent classes.  Extend `%pkg.isc.rest.model.resource`, then must override the RESOURCENAME and most likely should also override CheckPermission as well as the abstract methods.  

For an example of using `pkg.isc.rest.model.resource`, see: 
[UnitTest.isc.rest.sample.model.person](https://github.com/intersystems/isc-rest/blob/master/internal/testing/unit_tests/UnitTest/isc/rest/sample/model/settings.cls)


#### %pkg.isc.rest.model.dbMappedResource

To expose data that maps to a single %Persistent class, involving significant augmentation or cutting of the JSON that would normally be returned in the response if the %Persistent class were extending `%pkg.isc.rest.model.adaptor`, extend `%pkg.isc.rest.model.dbMappedResource` and overwrite the GeModelFromObject method to populate properties.  


### Permissions

Whether you extend `adaptor` or `proxy`, you must override the `CheckPermission()`
method, which by default says that nothing is allowed:

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
parameter in the persistent class to set it to 1.

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

NOTE: Studio will help with code completion for XML in this namespace.

[UnitTest.isc.rest.sample.model.person](../internal/testing/unit_tests/UnitTest/isc/rest/sample/model/person.cls) has annotated examples covering the full range of action capabilities. As a general guideline, do ensure that the HTTP verb matches the behavior of the endpoint (e.g., PUT and DELETE are idempotent, GET is safe, POST is neither).

#### Action Endpoints

| HTTP Verbs + Endpoint | Function |
| --------------------- | -------- |
| GET,PUT,POST,DELETE `/:resource/$:action` | Performs the named action on the specified resource. Constraints and format of URL parameters, body, and response contents will vary from action to action, but are well-defined via the ActionMap XData block. |
| GET,PUT,POST,DELETE `/:resource/:id/$:action` | Performs the named action on the specified resource instance. Constraints and format of URL parameters, body, and response contents will vary from action to action, but are well-defined via the ActionMap XData block. |

### Defining a Custom Resource

TODO: Talk about model.resource.

## Controlling Endpoints Exposed

TODO: Talk about Supports()

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

## Related Topics in InterSystems Documentation

* [Using the JSON Adaptor](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GJSON_adaptor)
* [Introduction to Creating REST Services](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GREST_intro)
* [Supporting CORS in REST Services](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GREST_cors)
* [Securing REST Services](https://docs.intersystems.com/irislatest/csp/docbook/DocBook.UI.Page.cls?KEY=GREST_securing)
