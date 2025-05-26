@{
    ExcludeRules = @(
        'PSAvoidUsingWriteHost',
        'PSAvoidUsingPlainTextForPassword'
    )

    IncludeRules = @(
        'PSUseApprovedVerbs',
        'PSAvoidUsingDeprecatedManifestFields'
    )

    Rules        = @{
        PSAvoidUsingWriteHost = @{
            Severity = 'Warning'
        }
    }
}
