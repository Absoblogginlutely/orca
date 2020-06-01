<#

231 - Check for duplicate anti-spam policies

#>

using module "..\ORCA.psm1"

class ORCA231 : ORCACheck
{
    <#
    
        CONSTRUCTOR with Check Header Data
    
    #>

    ORCA231()
    {
        $this.Control=231
        $this.Area="Anti-Spam Policies"
        $this.Name="Anti-Spam Policy Rules"
        $this.PassText="Each domain has a anti-spam policy applied to it, or the default policy is being used"
        $this.FailRecommendation="Check your anti-spam policies for duplicate rules. Some policies and settings may not be applying."
        $this.Importance="Exchange Online Protection anti-spam policies are applied using rules. The default policy applies in the absence of a custom policy. When creating custom policies, there may be duplication of settings and depending on the rules and priority, some policies or settings may not even apply. It's important in this circumstance to check that the desired settings are applied to the right users."
        $this.ExpandResults=$True
        $this.CheckType=[CheckType]::ObjectPropertyValue
        $this.ObjectType="Domain"
        $this.ItemName="Policy"
        $this.DataType="Priority"
        $this.Links= @{
            "Security & Compliance Center - Anti-spam policies"="https://protection.office.com/antispam"
        }
    }

    <#
    
        RESULTS
    
    #>

    GetResults($Config)
    {

        ForEach($AcceptedDomain in $Config["AcceptedDomains"]) 
        {

            # Set up the config object

            $Rules = @()

            # Go through each Safe Links Policy

            ForEach($Rule in ($Config["HostedContentFilterRule"] | Sort-Object Priority)) 
            {
                if($null -eq $Rule.SentTo -and $null -eq $Rule.SentToMemberOf -and $Rule.State -eq "Enabled")
                {
                    if($Rule.RecipientDomainIs -contains $AcceptedDomain.Name -and $Rule.ExceptIfRecipientDomainIs -notcontains $AcceptedDomain.Name)
                    {
                        # Policy applies to this domain

                        $Rules += New-Object -TypeName PSObject -Property @{
                            PolicyName=$($Rule.HostedContentFilterPolicy)
                            Priority=$($Rule.Priority)
                        }

                    }
                }

            }

            If($Rules.Count -gt 0)
            {
                $Count = 0

                ForEach($r in ($Rules | Sort-Object Priority))
                {

                    $Count++

                    $ConfigObject = [ORCACheckConfig]::new()

                    $ConfigObject.Object=$($AcceptedDomain.Name)
                    $ConfigObject.ConfigItem=$($r.PolicyName)
                    $ConfigObject.ConfigData=$($r.Priority)

                    If($Count -eq 1)
                    {
                        # First policy based on priority is a pass
                        $ConfigObject.SetResult([ORCAConfigLevel]::Standard,"Pass")
                    }
                    else
                    {
                        # Additional policies based on the priority should be listed as informational
                        $ConfigObject.InfoText = "There are multiple policies that apply to this domain, only the policy with the lowest priority will apply. This policy may not apply based on a lower priority."
                        $ConfigObject.SetResult([ORCAConfigLevel]::Informational,"Fail")
                    }    

                    $this.AddConfig($ConfigObject)
                }
            } 
            elseif($Rules.Count -eq 0)
            {
                <#
                    No policy is applying to this domain

                    For anti spam policies this is OK because we fall back to the default
                #>
                
                $ConfigObject = [ORCACheckConfig]::new()

                $ConfigObject.Object=$($AcceptedDomain.Name)
                $ConfigObject.ConfigItem="Default"
                $ConfigObject.ConfigData="Default"
                $ConfigObject.SetResult([ORCAConfigLevel]::Standard,"Pass")

                $this.AddConfig($ConfigObject)
            }

        }

    }

}