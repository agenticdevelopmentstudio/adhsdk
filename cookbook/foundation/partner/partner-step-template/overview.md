
`PartnerStepTemplate` fills `{key}` placeholders in the commands of a partner job's steps. A terminal step is a shell command line, so each value goes in as one shell word; a Claude step is a prompt, so its values are typed as written. A value that itself contains a placeholder is never substituted again, which matters because a value such as a commit subject is written by someone else.

