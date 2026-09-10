# AppLifecycleAnalyzer.ps1

> Every Entra ID app registration with its credentials, expiry and last sign-in, in one HTML report.

A tenant collects app registrations the way a garage collects boxes. This reads all of them in
one pass and writes a single self-contained HTML page you can hand to whoever owns the tenant.

Per app: its client secrets, certificates and federated credentials with the exact date each
one expires, when the app last signed in (combined from two Graph sources, because neither is
complete on its own), and whether the app has been deactivated or has no service principal at
all. Apps with no credentials and apps nobody has used in months are named rather than left for
you to spot in a list.

The report filters by activity, expiry and credential type, sorts on any column, and exports
what you filtered to CSV. Every row carries the command that cleans it up - one expired secret
by its keyId, every expired credential of an app, or the whole registration - and a detail view
shows each credential with its own command.

Read-only. It signs in with read scopes, reads, and writes a file. The cleanup commands are
text for you to copy; the script never runs one.

## Syntax

```powershell
./AppLifecycleAnalyzer.ps1 [[-OutputPath] <string>] [[-TenantId] <string>] [[-InactiveDays] <int>] [[-ExpiryWarningDays] <int>] [-AutoInstallModules] [-RequestWriteScopes] [<CommonParameters>]
```

## Requirements and notes

Prerequisites: PowerShell 7 or later, and the modules Microsoft.Graph.Authentication and
Microsoft.Graph.Applications. Install them once with Install-Module
Microsoft.Graph.Authentication, Microsoft.Graph.Applications -Scope CurrentUser, or pass
-AutoInstallModules and the script installs what is missing without asking.

RequiredPermissions: The delegated Graph scopes Application.Read.All, Directory.Read.All and
AuditLog.Read.All, which you consent to at sign-in. Sign-in activity comes from AuditLog and
needs Entra ID P1 or P2; without it the report still lists every app and its credentials, and
the activity column says so instead of guessing.

Writes: Nothing. The script reads Graph and writes one HTML file. Every cleanup command in
the report is text for you to copy - the script never runs one, and without
-RequestWriteScopes the session it opens cannot run one either.

License: MIT. https://github.com/simon-vedder/app-lifecycle-analyzer

## Parameters

| Name | Type | Required | Pipeline | Default | Description |
|---|---|---|---|---|---|
| `-OutputPath` | String | no | no |  | Where to write the report. Default: ./AppLifecycleAnalysis_<timestamp>.html next to you. |
| `-TenantId` | String | no | no |  | Tenant to sign in to. Without it the sign-in picks your home tenant. |
| `-InactiveDays` | Int32 | no | no | 90 | Days without a sign-in before an app counts as inactive. |
| `-ExpiryWarningDays` | Int32 | no | no | 30 | Days before a credential expires that it starts showing as expiring soon. |
| `-AutoInstallModules` | SwitchParameter | no | no |  | Install the missing Graph modules without asking first. |
| `-RequestWriteScopes` | SwitchParameter | no | no |  | Also ask for Application.ReadWrite.All at sign-in, so the cleanup commands in the report run in this same session. Read-only is the default on purpose; this is the deliberate opt-in. |

## Examples

### Example 1

```powershell
# Sign in to your home tenant, read, write the report next to you.
./AppLifecycleAnalyzer.ps1
```

### Example 2

```powershell
# A stricter reading: inactive after 60 days, warn two weeks before a credential expires.
./AppLifecycleAnalyzer.ps1 -InactiveDays 60 -ExpiryWarningDays 14
```

### Example 3

```powershell
# A named tenant and a path you choose, for a report you hand to someone.
./AppLifecycleAnalyzer.ps1 -TenantId 'contoso.onmicrosoft.com' -OutputPath './apps-q3.html'
```

### Example 4

```powershell
# Ask for write scopes too, so the cleanup commands in the report run in this same session.
# Read-only is the default on purpose; this is the deliberate opt-in.
./AppLifecycleAnalyzer.ps1 -RequestWriteScopes
```

---

[README](../../README.md) | [Tool page](https://simonvedder.com/tools/app-lifecycle-analyzer/)

*Generated from the comment-based help by `tools/New-CommandReference.ps1`. Edit the help in the script, not this file.*
