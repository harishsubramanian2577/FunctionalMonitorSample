import * from bat::BDD
import * from bat::Assertions
import * from bat::Mutable
import toBase64 from dw::core::Binaries
import * from dw::util::Values

var context = HashMap()

var cliId = secret('mon-client-id-alias') default 'Client ID not found'
var cliSecret = secret('mon-client-secret-alias') default 'Client Secret not found'

// Declare a variable holding a pipe-delimited string of application names
var appNamesToFilter = "hello-world-3345|checkperm-helloworld"

//var appNamesToFilter = "checkperm-helloworld"

// Split the string into an array of names
var nameList = appNamesToFilter splitBy "|"

// Define a variable with the list of application names to check.
var appNamesList = ["checkperm-helloworld", "devlocation"]

fun extractApplications(data, appNamesList1): Object  = (
    data filter (appNamesList1 contains $.artifact.name)
  // Map the filtered results to the desired structure
  map {
    applicationName: $.artifact.name,
    status: $.application.status
  }
)

// fun getAppNames(): Object = nameList


---
describe ("Check-API-Health-Suite") in [
  it must 'Create Access Token' in [
    POST `https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token` with {
        "body": {
          "client_id": cliId,
          "client_secret" : cliSecret,
          "grant_type" : "client_credentials"
        }
      } assert [
        $.response.status mustEqual 200,
        $.response.mime mustEqual "application/json"
      ] execute [
          context.set('access_token', $.response.body.access_token)
        ] 
    ],
    it should "Get Applications Status" in [
      GET `https://anypoint.mulesoft.com/armui/api/v2/applications` with {
        "headers": {
          "Authorization": "Bearer $(context.get('access_token'))",
          "X-ANYPNT-ORG-ID": "a19065cb-4dd4-4916-9401-bb64b169742c",
          "X-ANYPNT-ENV-ID": "2e16bf69-7e76-4387-ad51-1fdd939b4d86"
        }
      } assert [
          $.response.status mustEqual 200,
          // every($.response.body.data..application.status) mustMatch oneOf(["RUNNING"])

          //every(context.get('appDetails').data filter (appNames contains $.artifact.name)).application.status mustMatch oneOf(["RUNNING"])
          //every($.response.body.data filter (getAppNames() contains $.artifact.name)).application.status mustMatch oneOf(["RUNNING"])

          //Working below
          every(extractApplications($.response.body.data, appNamesList))..status mustMatch oneOf(["RUNNING"])
      ]execute [
        context.set('appDetails', $.response.body.data),
        
        //context.set('appDetails', customFunctions::extractApplications($.response.body.data)),
        //log($.response) // <--- Then we’ll log the response

        //log('data is', $.response.body.data),
        //log("apps", extractApplications($.response.body.data)),
        
        //context.set('appDetails', extractApplications($.response.body.data)),
        log("INFO", "Execution Completed"),
        log("appDetails", context.get('appDetails'))
      ]
    ],
     it must "Check if Hello worrld apis i.e 'checkperm-helloworld, devlocation' are Running" in [

      POST `https://anypoint.mulesoft.com/accounts/api/v2/oauth2/token` with {
        "body": {
          "client_id": cliId,
          "client_secret" : cliSecret,
          "grant_type" : "client_credentials"
        }
      }
      assert [
        //(context.get('appDetails') filter ($.artifact.name == "checkperm-helloworld")).application.status mustMatch oneOf(["RUNNING"])   
        //every(extractApplications($.response.body.data))..status mustMatch oneOf(["RUNNING"])
        // Just Sanity check that login to platform is working
        $.response.status mustEqual 200,
        every(extractApplications(context.get('appDetails'),appNamesList))..status mustMatch oneOf(["RUNNING"])
      ]
    ]
]