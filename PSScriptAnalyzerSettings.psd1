@{
  Severity            = @('Error', 'Warning')
  IncludeDefaultRules = $true
  ExcludeRules        = @(
    # This is an interactive console script: the progress it prints is for a person watching it
    # run, not data for a pipeline. The one thing it returns to the caller is the report file.
    'PSAvoidUsingWriteHost',

    # The BOM exists so Windows PowerShell 5.1 reads a UTF-8 file correctly. This script declares
    # #Requires -Version 7.0, and 7 reads UTF-8 without a BOM on every platform, so the BOM would
    # only be noise in a file people download and read before running it.
    'PSUseBOMForUnicodeEncodedFile'
  )
  Rules               = @{
    # Two spaces, because that is what this script is written in. The analyzer enforces the
    # convention the file already has; it does not import one from another repository.
    PSUseConsistentIndentation = @{ Enable = $true; IndentationSize = 2; Kind = 'space'; PipelineIndentation = 'IncreaseIndentationForFirstPipeline' }
    PSUseConsistentWhitespace  = @{ Enable = $true; CheckInnerBrace = $true; CheckOpenBrace = $true; CheckOpenParen = $true; CheckOperator = $true; CheckPipe = $true; CheckSeparator = $true; IgnoreAssignmentOperatorInsideHashTable = $true }
    PSPlaceOpenBrace           = @{ Enable = $true; OnSameLine = $true; NewLineAfter = $true; IgnoreOneLineBlock = $true }
    PSPlaceCloseBrace          = @{ Enable = $true; NewLineAfter = $true; IgnoreOneLineBlock = $true; NoEmptyLineBefore = $false }
    PSAvoidUsingCmdletAliases  = @{ Enable = $true }
  }
}
