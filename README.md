# How to use

1. Create an `.env` file and add the required variables that can be found in the `.env.example`
2. Run the `Start-O365AuditSubscriptions.ps1`

## Error handling

| Error code | Note                                                                                                                                                                                                    |
| ---------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| #0001      | Auditing is disabled in Purview. [Read more](https://www.tenable.com/audits/items/CIS_Microsoft_365_v1.5.0_E3_Level_1.audit:63d04d00b1e7ed175c72ae6c2e2c80ea), change may take up to 24 hours to apply. |
| #0002      | Subscription is already active, no change needed.                                                                                                                                                       |
| #10001     | `check_login_whitelist.py` did not get the access_token from Microsoft OAuth2.0. Double check tenant id, client id and client secret.                                                                   |
| #10002     | `check_login_whitelist.py` Failed to read Wazuh event object.                                                                                                                                           |
