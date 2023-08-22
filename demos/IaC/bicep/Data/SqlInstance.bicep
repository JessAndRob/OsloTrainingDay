targetScope = 'resourceGroup'
@minLength(1)
@maxLength(63)
@description('The name of the SQL server - Lowercase letters, numbers, and hyphens.Cant start or end with hyphen.')
param SqlInstanceName string
@description('The location for the SQL Server')
param location string = 'northeurope'
param tags object
@description('The name of the administrator login')
param administratorLogin string
@description('The password for the SQL Server Administratoe')
@secure()
param administratorLoginPassword string
@allowed([
  ''
  'dev'
  'test'
  'prod'
])
@description('The environment that is being deployed')
param environment string = ''

param minimalTlsVersion string = '1.2' // 1.0,1.1,1.2
param publicNetworkAccess string = 'Disabled' // 'Disabled','Enabled'
param ActiveDirectoryAdminUser string
param ActiveDirectoryAdminUserSid string
param tenantid string
param azureADOnlyAuthentication bool = false
param ExternalAdministratorPrincipalType string // User Application Group


@minLength(1)
@maxLength(128)
@description('Name of the inventory database - demo1 - Cant use: <>*%&:\\/? or control characters Cant end with period or space')
param SqldatabaseNames array
param dbSkuName string // for example GP_Gen5_2, BC_Gen5_10, HS_Gen5_8, P5, S0 etc
param dbSkuFamily string // Gen4, Gen5
param collation string = 'SQL_Latin1_General_CP1_CI_AS' //
param zoneRedundant bool = false // 	Whether or not this database is zone redundant, which means the replicas of this database will be spread across multiple availability zones.
param licenseType string = 'LicenseIncluded' //	The license type to apply for this database. LicenseIncluded if you need a license, or BasePrice if you have a license and are eligible for the Azure Hybrid Benefit. - LicenseIncluded or BasePrice


resource sql 'Microsoft.Sql/servers@2022-11-01-preview' = {
  name: SqlInstanceName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: administratorLogin
    administratorLoginPassword: administratorLoginPassword
    minimalTlsVersion: minimalTlsVersion
    publicNetworkAccess: publicNetworkAccess
    administrators: {
      administratorType: 'ActiveDirectory'
      login: ActiveDirectoryAdminUser
      sid: ActiveDirectoryAdminUserSid
      tenantId: tenantid
      azureADOnlyAuthentication: azureADOnlyAuthentication
      principalType: ExternalAdministratorPrincipalType
    }
  }
}

// SQL Databases

resource symbolicname 'Microsoft.Sql/servers/databases@2022-11-01-preview' = [for item in SqldatabaseNames:{
  parent: sql
  name: '${item}-${environment}'
  location: location
  tags: tags
  sku: {
    name: dbSkuName
    family: dbSkuFamily
  }
  properties: {
    collation: collation
    zoneRedundant: zoneRedundant
    licenseType: licenseType
  }
}]
