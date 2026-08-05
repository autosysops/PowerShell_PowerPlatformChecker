function Expand-PowerPlatformCheckerScopedReachability {
    <#
    .SYNOPSIS
        Expands connected entity sets for scoped diagrams through relation traversal.

    .DESCRIPTION
        Starting from already connected entity set names, walks entity relations until no new
        in-solution entities are discovered. Optionally collects unresolved relation endpoints
        as default-entity candidates so external dependencies remain visible.

    .PARAMETER ConnectedEntities
        Initially connected in-solution entity set names.

    .PARAMETER ConnectedDefaultEntities
        Initially connected unresolved/default entity identifiers.

    .PARAMETER EntityBySetName
        Lookup table from entity set name to entity metadata object.

    .PARAMETER EntityByLogicalName
        Lookup table from entity logical name to entity metadata object.

    .PARAMETER IncludeDefaultEntities
        Include unresolved relation endpoints in the default entity set.

    .EXAMPLE
        Expand scoped entity reachability.

        PS> Expand-PowerPlatformCheckerScopedReachability -ConnectedEntities $connected -EntityBySetName $setMap -EntityByLogicalName $logicalMap -IncludeDefaultEntities

        Returns expanded connected entity and default entity collections for scoped rendering.
    #>

    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)]
        [string[]] $ConnectedEntities = @(),

        [Parameter(Mandatory = $false)]
        [string[]] $ConnectedDefaultEntities = @(),

        [Parameter(Mandatory = $true)]
        [hashtable] $EntityBySetName,

        [Parameter(Mandatory = $true)]
        [hashtable] $EntityByLogicalName,

        [Parameter(Mandatory = $false)]
        [switch] $IncludeDefaultEntities
    )

    $expandedConnectedEntities = @($ConnectedEntities | Where-Object { $_ } | Select-Object -Unique)
    $expandedConnectedDefaultEntities = @($ConnectedDefaultEntities | Where-Object { $_ } | Select-Object -Unique)

    # Iterate to a fixed point so transitive entity relations are included in scoped output.
    $hasChanges = $true
    while ($hasChanges) {
        $hasChanges = $false

        foreach ($connectedEntitySetName in @($expandedConnectedEntities)) {
            if (-not $EntityBySetName.ContainsKey($connectedEntitySetName)) {
                continue
            }

            $entity = $EntityBySetName[$connectedEntitySetName]
            foreach ($relation in @($entity.Relations)) {
                if (-not $relation.Source -or -not $relation.Target) {
                    continue
                }

                if ($entity.Name -and $relation.Source -and $relation.Source.ToLower() -ne $entity.Name.ToLower()) {
                    continue
                }

                $relationSourceKey = [string]$relation.Source.ToLower()
                $relationTargetKey = [string]$relation.Target.ToLower()
                $sourceEntityObj = if ($EntityByLogicalName.ContainsKey($relationSourceKey)) { $EntityByLogicalName[$relationSourceKey] } else { $null }
                $targetEntityObj = if ($EntityByLogicalName.ContainsKey($relationTargetKey)) { $EntityByLogicalName[$relationTargetKey] } else { $null }

                # Both endpoints resolve to in-solution entities: keep expanding the connected set.
                if ($sourceEntityObj -and $targetEntityObj) {
                    $sourceSet = [string]$sourceEntityObj.EntitySetName.ToLower()
                    $targetSet = [string]$targetEntityObj.EntitySetName.ToLower()
                    if ($sourceSet -notin $expandedConnectedEntities) {
                        $expandedConnectedEntities += $sourceSet
                        $hasChanges = $true
                    }
                    if ($targetSet -notin $expandedConnectedEntities) {
                        $expandedConnectedEntities += $targetSet
                        $hasChanges = $true
                    }
                }
                # Only one side resolves: optionally preserve the unresolved side as a default node.
                elseif ($sourceEntityObj -and $IncludeDefaultEntities.IsPresent) {
                    $defaultTarget = [string]$relation.Target.ToLower()
                    if ($defaultTarget -notin $expandedConnectedDefaultEntities) {
                        $expandedConnectedDefaultEntities += $defaultTarget
                        $hasChanges = $true
                    }
                }
                elseif ($targetEntityObj -and $IncludeDefaultEntities.IsPresent) {
                    $defaultSource = [string]$relation.Source.ToLower()
                    if ($defaultSource -notin $expandedConnectedDefaultEntities) {
                        $expandedConnectedDefaultEntities += $defaultSource
                        $hasChanges = $true
                    }
                }
            }
        }

        $expandedConnectedEntities = @($expandedConnectedEntities | Select-Object -Unique)
        $expandedConnectedDefaultEntities = @($expandedConnectedDefaultEntities | Select-Object -Unique)
    }

    return [pscustomobject]@{
        ConnectedEntities = @($expandedConnectedEntities)
        ConnectedDefaultEntities = @($expandedConnectedDefaultEntities)
    }
}
