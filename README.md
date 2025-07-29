# How to use

1. Create an `.env` file and add the required variables that can be found in the `.env.example`
2. Run the `Start-O365AuditSubscriptions.ps1`

## Error handling

| Error code | Note                                                                                                             |
| ---------- | ---------------------------------------------------------------------------------------------------------------- |
| #0001      | Auditing is disabled in Purview. [Read more](https://learn.microsoft.com/en-us/purview/audit-log-enable-disable) |
| #0002      | Subscription is already active, no change needed.                                                                |
