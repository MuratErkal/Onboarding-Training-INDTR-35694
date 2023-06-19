# Lightning Flows Module:
## Task 1
### Flows:
- Update Address and Weather Data
## Task 2
### Flows:
- Send Auto Responses to Cases

# LWC Module:
## Task 1
### Custom Metadata Types:
- OSF WtC Form
- OSF WtC Form Field
### LWC:
- osfWebToCaseLWC
### Classes:
- OSF_WebToCaseLWCPicklist
- OSF_WebToCaseLWCPicklistTest
- OSF_WebToCaseLWC
- OSF_WebToCaseLWCTest
- OSF_CaseTriggerHandler -> .beforeInsert
- OSF_CaseTriggerHelper -> .createPersonAccountsFromCases
### Triggers:
- OSF_CaseTrigger
## Task 2
### LWC:
- osfPersonAccountKPI
- osfPersonAccountKPICell
### Classes:
- OSF_PersonAccountKPI
- OSF_PersonAccountKPITest

# Apex Module:
## Task 1
### LWC:
- osfMasterAccountMostPurchased
### Classes:
- OSF_GetMasterAccountMostPurchased
- OSF_GetMasterAccountMostPurchasedTest
- OSF_PersonAccountTriggerHandler
- OSF_PersonAccountTriggerHelper
- OSF_PersonAccountTriggerTest
- OSF_OrderTriggerHandler
- OSF_OrderTriggerHelper
- OSF_OrderTriggerHelperTest
### Triggers:
- OSF_PersonAccountTrigger
- OSF_OrderTrigger
- OSF_ContractTrigger
## Task 2
### Classes:
- OSF_CaseTriggerHandler -> .beforeUpdate
- OSF_CaseTriggerHelper -> .getOrdersToUpdateMap & .updateOrders
## Task 3
### Classes:
- OSF_CaseTriggerHandler -> .afterInsert
- OSF_CaseTriggerHelper -> .getEmailCasesToUpdateLang & .updateEmailCasesLang
- DetectLanguageWrapper
## Task 4
### Classes:
- OSF_WeatherUnitConverter
- CelsiusToFah
