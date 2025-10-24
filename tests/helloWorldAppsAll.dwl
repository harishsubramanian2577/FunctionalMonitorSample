import * from bat::BDD
import * from bat::Assertions
import * from bat::Mutable
import toBase64 from dw::core::Binaries
import * from dw::util::Values

import tests::customFunctions

var context = HashMap()

//var cliId = secret('mon-client-id-alias') default 'Client ID not found'
//var cliSecret = secret('mon-client-secret-alias') default 'Client Secret not found'

var cliId = "dbceb4d467664d8382a5bcf1a628eaa0"
var cliSecret = "DF7a68e65163496EB2c0D56155D266E4"

var api_deploy_endpoint = config.urlAppDeployDetails
var api_appDeployDetails_endpoint = config.urlAppsDetails
var api_auth_endpoint = config.urlAuth
var orgId = config.organizationId
var envId = config.environmentId

// Define a variable with the list of application names to check.
var appNamesList = ["checkperm-helloworld", "devlocation"]
var nameList = config.ignoreList splitBy "|"

fun extractApplications(data, appNamesList1): Object  = (
  //data filter (appNamesList1 contains $.artifact.name)
  data filter (not (appNamesList1 contains $.artifact.name))
  // Map the filtered results to the desired structure
  map {
    id: $.id,
    applicationName: $.artifact.name,
    status: $.application.status
  }
)

fun notrunningapps(data): Object  = (
  //data filter (appNamesList1 contains $.artifact.name)
  data filter ($.application.status == "NOT_RUNNING")
  // Map the filtered results to the desired structure
  map {
    applicationName: $.artifact.name
  }
)

fun getApplicationStatus(id: String): Object =  (
    GET `$(api_deploy_endpoint)/$(id)` with {
        "headers": {
          "Authorization": "Bearer $(context.get('access_token'))"
        }
    }
)

---
describe ("Check-API-Health-Suite") in [
  it must 'Create Access Token' in [
    POST `$(api_auth_endpoint)` with {
      "body": {
        "client_id": cliId,
        "client_secret" : cliSecret,
        "grant_type" : "client_credentials"
      }
    } assert [
      $.response.status mustEqual 200,
      $.response.mime mustEqual "application/json"
    ] execute [
        context.set('access_token', $.response.body.access_token),
        log("orgId", orgId),
        log("envId", envId)
    ] 
  ],
  it must "Get Application Names and deployment Ids" in [
    GET `$(api_appDeployDetails_endpoint)` with {
      "headers": {
        "Authorization": "Bearer $(context.get('access_token'))",
        "X-ANYPNT-ORG-ID": orgId,
        "X-ANYPNT-ENV-ID": envId
      }
    }
    execute [
      context.set('appDetails', $.response.body.data),
      log("INFO", "Execution Completed"),
      log("appDetails", context.get('appDetails')),
      
      //$.response.body.data map context.set($.artifact.name, $.id),
      //log("checkperm-helloworld", context.get('checkperm-helloworld')),


      //$.response.body.data filter ($.application.status == "NOT_RUNNING") map context.set($.artifact.name, $.application.status),
      //log("checkperm-helloworld", context.get('checkperm-helloworld')),

      //context.set("NOTRUNNINGAPPS", $.response.body.data filter ($.application.status == "NOT_RUNNING") map $.artifact.name),

      log("sss",notrunningapps($.response.body.data)),
      log("ss1", $.response.body.data filter ($.application.status == "NOT_RUNNING") map $.artifact.name),

      context.set("NOTRUNNINGAPPS",notrunningapps($.response.body.data)),
      log("NOTRUNNINGAPPS", context.get('NOTRUNNINGAPPS'))

      //context.set('total', $.response.body.total),
      //context.set('count', 1),
      //log("current Count is ", context.get('count'))
    ] 
    assert [
        $.response.status mustEqual 200,

        //every(customFunctions::extractApplications(context.get('appDetails'),appNamesList))..status mustMatch oneOf(["RUNNING"])
        //every(extractApplications(context.get('appDetails'),nameList))..status mustMatch oneOf(["RUNNING"])

        //(context.get('appDetails') filter ($.application.status == "NOT_RUNNING") map $.artifact.name) mustEqual (context.get('appDetails') filter ($.application.status == "NOT_RUNNING") map $.artifact.name),

        //extractApplications(context.get('appDetails'),appNamesList)..applicationName isNotEmpy,

        every(extractApplications(context.get('appDetails'),appNamesList))..status mustMatch oneOf(["RUNNING"])

      ]
  ]
]