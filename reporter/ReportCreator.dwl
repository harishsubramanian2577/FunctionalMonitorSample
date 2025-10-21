%dw 2.0
output application/json

fun extractApplications(data) =
data flatMap ((item) ->
item.result filter ((subItem) -> subItem.name == "Get Applications Status")  flatMap ((subSubItem) ->
subSubItem.result flatMap ((subSubSubItem) ->
subSubSubItem.result.response.body.data filter ((app) ->
app.application.status == "NOT_RUNNING"
) map ((app) ->
{
applicationName: app.artifact.name,
status: app.application.status
}
)
)
)
)
---
{
    suiteName: payload.name,
    message: "Please find below the list of applications that are not running..",
    applicationStatus: extractApplications(payload.result)
}