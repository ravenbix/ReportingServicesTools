function New-RsLinkedReport {
    <#
        .SYNOPSIS
            Creates a linked report in SQL Server Reporting Services (SSRS).

        .DESCRIPTION
            This function creates a linked report under a specified folder using an existing report definition.
            It allows setting report metadata like name, description, and visibility (hidden).

        .PARAMETER RsItem
            Path to the existing report item to link from.

        .PARAMETER RsFolder
            Path to the folder where the linked report will be created.

        .PARAMETER Name
            Name of the new linked report.

        .PARAMETER Description
            Optional description for the linked report.

        .PARAMETER Hidden
            Switch to mark the linked report as hidden.

        .PARAMETER ReportServerUri
            Specify the Report Server URL to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER Credential
            Specify the password to use when connecting to your SQL Server Reporting Services Instance.
            Use the "Connect-RsReportServer" function to set/update a default value.

        .PARAMETER Proxy
            Report server proxy to use.
            Use "New-RsWebServiceProxy" to generate a proxy object for reuse.
            Useful when repeatedly having to connect to multiple different Report Server.

        .EXAMPLE
            New-RsLinkedReport -RsItem "/Reports/SalesSummary" -RsFolder "/LinkedReports" -Name "Sales_Linked"
            Description
            -----------
            Creates a linked report named 'Sales_Linked' in the '/LinkedReports' folder using the source report '/Reports/SalesSummary'.

        .EXAMPLE
            New-RsLinkedReport -RsItem "/Reports/SalesSummary" -RsFolder "/LinkedReports" -Name "Sales_Linked" -Description "Monthly Sales Snapshot"
            Description
            -----------
            Creates a linked report with a custom description in the specified folder.

        .EXAMPLE
            New-RsLinkedReport -RsItem "/Reports/SalesSummary" -RsFolder "/LinkedReports" -Name "Sales_Linked" -Hidden
            Description
            -----------
            Creates a linked report and marks it as hidden in the SSRS folder view.

        .EXAMPLE
            New-RsLinkedReport -RsItem "/Reports/SalesSummary" -RsFolder "/LinkedReports" -Name "Sales_Linked" -Description "Snapshot" -Hidden
            Description
            -----------
            Creates a linked report with both a custom description and hidden flag.

        .EXAMPLE
            New-RsLinkedReport -RsItem "/Reports/SalesSummary" -RsFolder "/LinkedReports" -Name "Sales_Linked" -ReportServerUri "http://reportserver/ReportServer"
            Description
            -----------
            Creates a linked report using a specified Report Server URI, useful when not using `Connect-RsReportServer`.

        .EXAMPLE
            $cred = Get-Credential
            New-RsLinkedReport -RsItem "/Reports/SalesSummary" -RsFolder "/LinkedReports" -Name "Sales_Linked" -Credential $cred
            Description
            -----------
            Uses explicit credentials to authenticate with the Report Server during linked report creation.

        .EXAMPLE
            $proxy = New-RsWebServiceProxy -ReportServerUri "http://reportserver/ReportServer"
            New-RsLinkedReport -RsItem "/Reports/SalesSummary" -RsFolder "/LinkedReports" -Name "Sales_Linked" -Proxy $proxy
            Description
            -----------
            Uses a pre-created SSRS web service proxy object to create the linked report — useful in script loops or automation.

        .EXAMPLE
            $cred = Get-Credential
            $proxy = New-RsWebServiceProxy -ReportServerUri "http://reportserver/ReportServer" -Credential $cred
            New-RsLinkedReport -RsItem "/Reports/SalesSummary" -RsFolder "/LinkedReports" -Name "Sales_Linked" -Description "Confidential" -Hidden -Credential $cred -Proxy $proxy
            Description
            -----------
            Demonstrates full usage: custom description, hidden flag, explicit credentials, and reuse of a web service proxy for authentication and performance.

        .EXAMPLE
            $sourceReport = "/Reports/SalesSummary"
            $targetFolder = "/LinkedReports"
            $reportServerUri = "http://reportserver/ReportServer"
            $namesAndDescriptions = @(
                @{ Name = "Sales_Linked_West"; Description = "Sales report for the Western region" },
                @{ Name = "Sales_Linked_East"; Description = "Sales report for the Eastern region" },
                @{ Name = "Sales_Linked_North"; Description = "Sales report for the Northern region" },
                @{ Name = "Sales_Linked_South"; Description = "Sales report for the Southern region" }
            )
            foreach ($item in $namesAndDescriptions) {
                New-RsLinkedReport -RsItem $sourceReport -RsFolder $targetFolder -Name $item.Name -Description $item.Description -ReportServerUri $reportServerUri
            }
            Description
            -----------
            Creates multiple linked reports from the same source report using an array of name-description pairs, specifying the Report Server URI.

        .EXAMPLE
            $reportServerUri = "http://reportserver/ReportServer"
            $csv = Import-Csv "linkedReports.csv"
            foreach ($item in $csv) {
                New-RsLinkedReport -RsItem "/Reports/SalesSummary" -RsFolder "/LinkedReports" -Name $item.Name -Description $item.Description -ReportServerUri $reportServerUri
            }
            Description
            -----------
            Reads a CSV file with Name and Description columns to generate multiple linked reports from a shared source, explicitly specifying the Report Server URI.
    #>

    [CmdletBinding()]
    param (
        [Alias('ReportPath','ItemPath','Path', 'ParentReportPath', 'ParentItemPath', 'ParentPath')]
        [Parameter(Mandatory=$True)]
        [ValidateNotNullOrEmpty()]
        [string] $RsItem,

        [Alias('Folder', 'FolderPath', 'LinkedReportFolder', 'LinkedReportFolderPath')]
        [Parameter(Mandatory = $True, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string] $RsFolder,

        [Alias('LinkedReportName')]
        [Parameter(Mandatory = $True)]
        [ValidateNotNullOrEmpty()]
        [string] $Name,

        [Alias('LinkedReportDescription')]
        [string] $Description,

        [switch] $Hidden,

        [string] $ReportServerUri,
        
        [Alias('ReportServerCredentials')]
        [System.Management.Automation.PSCredential] $Credential,
        
        $Proxy
    )

    begin {
        $Proxy = New-RsWebServiceProxyHelper -BoundParameters $PSBoundParameters
    }

    process {
        try {
            $namespace = $Proxy.GetType().Namespace
            $propertyDataType = "$namespace.Property"
            $additionalProperties = New-Object System.Collections.Generic.List[$propertyDataType]

            if ($Description) {
                $descriptionProperty = New-Object $propertyDataType
                $descriptionProperty.Name = 'Description'
                $descriptionProperty.Value = $Description
                $additionalProperties.Add($descriptionProperty)
            }

            if ($Hidden.IsPresent) {
                $hiddenProperty = New-Object $propertyDataType
                $hiddenProperty.Name = 'Hidden'
                $hiddenProperty.Value = "True"
                $additionalProperties.Add($hiddenProperty)
            }

            Write-Verbose "Creating linked report '$Name' in '$RsFolder'..."
            $Proxy.CreateLinkedItem($Name, $RsFolder, $RsItem, $additionalProperties) | Out-Null
            Write-Verbose "Linked report created successfully."
        }
        catch {
            throw "Exception occurred while creating linked report: $($_.Exception.Message)"
        }
    }
}
