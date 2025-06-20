@description('The name of the existing Front Door/CDN Profile.')
param profileName string

@description('Endpoints to deploy to Front Door.')
param endpoints array

@description('Origin Groups to deploy to Front Door.')
param originGroups array

@description('Origins to deploy to Front Door.')
param origins array

@description('Optional. Secrets to deploy to Front Door. Required if customer certificates are used to secure endpoints.')
param secrets array = []

@description('Optional. Custom domains to deploy to Front Door.')
param customDomains array = []

@description('Routes to deploy to Front Door.')
param routes array

@description('Optional. RuleSets to deploy to Front Door.')
param ruleSets array = []

@description('Optional. Security Policies to deploy to Front Door.')
param securityPolicies array = []

resource profile 'Microsoft.Cdn/profiles@2022-11-01-preview' existing = {
  name: profileName
}

resource endpoint 'Microsoft.Cdn/profiles/afdEndpoints@2022-11-01-preview' = [for e in endpoints: {
  parent: profile
  name: e.name
  location: 'global'
  properties: {
    enabledState: contains(e, 'enabledState') ? e.enabledState : 'Enabled'
    autoGeneratedDomainNameLabelScope: contains(e, 'autoGeneratedDomainNameLabelScope') ? e.autoGeneratedDomainNameLabelScope : 'TenantReuse'
  }
}]

resource originGroup 'Microsoft.Cdn/profiles/originGroups@2022-11-01-preview' = [for og in originGroups: {
  parent: profile
  name: og.name
  properties: {
    loadBalancingSettings: contains(og, 'loadBalancingSettings') ? {
      sampleSize: contains(og.loadBalancingSettings, 'sampleSize') ? og.loadBalancingSettings.sampleSize : 4
      successfulSamplesRequired: contains(og.loadBalancingSettings, 'successfulSamplesRequired') ? og.loadBalancingSettings.successfulSamplesRequired : 3
      additionalLatencyInMilliseconds: contains(og.loadBalancingSettings, 'additionalLatencyInMilliseconds') ? og.loadBalancingSettings.additionalLatencyInMilliseconds : 50
    } : {
      sampleSize: 4
      successfulSamplesRequired: 3
      additionalLatencyInMilliseconds: 50
    }
    healthProbeSettings: contains(og, 'healthProbeSettings') ? {
      probePath: contains(og.healthProbeSettings, 'probePath') ? og.healthProbeSettings.probePath : '/'
      probeRequestType: contains(og.healthProbeSettings, 'probeRequestType') ? og.healthProbeSettings.probeRequestType : 'HEAD'
      probeProtocol: contains(og.healthProbeSettings, 'probeProtocol') ? og.healthProbeSettings.probeProtocol : 'Http'
      probeIntervalInSeconds: contains(og.healthProbeSettings, 'probeIntervalInSeconds') ? og.healthProbeSettings.probeIntervalInSeconds : 240
    } : {}
    sessionAffinityState: contains(og, 'sessionAffinityState') ? og.sessionAffinityState : 'Disabled'
  }
}]

resource origin 'Microsoft.Cdn/profiles/originGroups/origins@2022-11-01-preview' = [for o in origins: {
  dependsOn: [
    originGroup
  ]
  #disable-next-line use-parent-property
  name: '${profile.name}/${o.originGroupName}/${o.originName}'
  properties: {
    hostName: o.hostName
    httpPort: contains(o, 'httpPort') ? o.httpPort : 80
    httpsPort: contains(o, 'httpsPort') ? o.httpsPort : 443
    originHostHeader: contains(o, 'originHostHeader') ? o.originHostHeader : o.hostName
    enforceCertificateNameCheck: contains(o, 'enforceCertificateNameCheck') ? o.enforceCertificateNameCheck : true
    priority: contains(o, 'priority') ? o.priority : 1
    weight: contains(o, 'weight') ? o.weight : 1000
    sharedPrivateLinkResource: contains(o, 'sharedPrivateLinkResource') ? o.sharedPrivateLinkResource : null
    enabledState: contains(o, 'enabledState') ? o.enabledState : 'Enabled'
  }
}]

resource secret 'Microsoft.Cdn/profiles/secrets@2022-11-01-preview' = [for s in secrets: {
  parent: profile
  name: s.secretName
  properties: {
    parameters: {
      type: 'CustomerCertificate'
      useLatestVersion: true
      secretSource: {
        id: s.parameters.certificateSecretId
      }
    }
  }
}]

resource customDomain 'Microsoft.Cdn/profiles/customDomains@2022-11-01-preview' = [for c in customDomains: {
  parent: profile
  dependsOn: [
    secret // secrets must exist before custom domains are created
  ]
  name: replace(c.customDomainName, '.', '-')
  properties: {
    hostName: c.hostName
    azureDnsZone: c.dnsZoneId == null ? null : {
      #disable-next-line use-resource-id-functions
      id: c.dnsZoneId
    }
    tlsSettings: {
      certificateType: c.tlsSettings.certificateType
      minimumTlsVersion: 'TLS12'
      secret: c.tlsSettings.certificateType == 'CustomerCertificate' ? {
        id: az.resourceId('Microsoft.Cdn/profiles/secrets', profile.name, c.tlsSettings.secretName)
      } : null
    }
  }
}]

resource ruleset 'Microsoft.Cdn/profiles/ruleSets@2022-11-01-preview' = [for rs in ruleSets: {
  name: rs.ruleSetName
  parent: profile
}]

resource route 'Microsoft.Cdn/profiles/afdEndpoints/routes@2022-11-01-preview' = [for r in routes: {
  dependsOn: [
    endpoint
    origin
    customDomain
    ruleset
  ]
  #disable-next-line use-parent-property
  name: '${profile.name}/${r.endpointName}/${r.routeName}'
  properties: {
    originGroup: {
      id: az.resourceId('Microsoft.Cdn/profiles/origingroups', profile.name, r.originGroupName)
    }
    supportedProtocols: contains(r, 'supportedProtocols') ? r.supportedProtocols : [ 'Https' ]
    patternsToMatch: contains(r, 'patternsToMatch') ? r.patternsToMatch : []
    forwardingProtocol: contains(r, 'forwardingProtocol') ? r.forwardingProtocol : 'HttpsOnly'
    customDomains: [for c in contains(r, 'customDomains') ? r.customDomains : []: {
      id: az.resourceId('Microsoft.Cdn/profiles/customdomains', profile.name, replace(c.name, '.', '-'))
    }]
    ruleSets: [for rs in contains(r, 'ruleSets') ? r.ruleSets : []: {
      id: az.resourceId('Microsoft.Cdn/profiles/ruleSets', profile.name, rs.name)
    }]
    linkToDefaultDomain: contains(r, 'linkToDefaultDomain') ? r.linkToDefaultDomain : 'Enabled'
    httpsRedirect: contains(r, 'httpsRedirect') ? r.httpsRedirect : 'Enabled'
    cacheConfiguration: contains(r, 'cacheConfiguration') ? r.cacheConfiguration : null
  }
}]

var policyCustomDomainsAssociations = map(filter(securityPolicies, sp => !empty(sp.customDomains)), sp => {
    policyName: sp.policyName
    ids: map(sp.customDomains, d => az.resourceId('Microsoft.Cdn/profiles/customDomains', profile.name, replace(d.name, '.', '-')))
  })

var policyEndpointAssociations = map(filter(securityPolicies, sp => !empty(sp.endpoints)), sp => {
    policyName: sp.policyName
    ids: map(sp.endpoints, ep => az.resourceId('Microsoft.Cdn/profiles/afdEndpoints', profile.name, ep.name))
  })

var policyDomainAssociations = union(policyCustomDomainsAssociations, policyEndpointAssociations)


resource policy 'Microsoft.Cdn/profiles/securityPolicies@2022-11-01-preview' = [for s in securityPolicies: {
  parent: profile
  dependsOn: [
    endpoint
    customDomain
  ]
  name: s.policyName
  properties: {
    parameters: {
      type: 'WebApplicationFirewall'
      associations: [
        {
          patternsToMatch: [ '/*' ]
          domains: [for id in flatten(map(filter(policyDomainAssociations, f => f.policyName == s.policyName), policy => policy.ids)): {
            #disable-next-line use-resource-id-functions
            id: id
          }]
        }
      ]
      wafPolicy: {
        #disable-next-line use-resource-id-functions
        id: s.firewallPolicyId
      }
    }
  }
}]

