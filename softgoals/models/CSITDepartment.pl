% CSITDepartment  (nfr2 dialect: <- rules, <~ contribution lists)
:- discontiguous (<-)/2, (<~)/2.
:- dynamic (<-)/2, (<~)/2.
types(goal,
  [callsBeRecordedIntoADataBase1,
   itTrainingSupportBeGivenToEmployees,
   callCenterServerAndSchedulingSystemBeIntegrated,
   integrateITSystems,
   performanceReviewInformationBeCollectedInDataBase,
   csBeNotForProfit, anITTrainerBePresent1,
   itProvidersHaveKnowledgeOfFundraisingAndMarketing,
   hardwareBeAcquired, anITTrainerBePresent,
   telephonyBeImplementedAndManaged1, aTrainingComputerBePresent1,
   itProvidersHaveKnowledgeOfCounselling,
   performanceReviewInformationBeCollectedInDataBase1,
   itSystemsBeIntegrated, acquireSoftware, webServerBeAcquired,
   csBeNotForProfit1, callsBeRecordedIntoADataBase, itBeUpgraded,
   webSoftwareBeAcquired, aTrainingComputerBePresent,
   providePeerToPeerAccessRegionalOffices
  ]).
types(softgoal,
  [easilyAccessableTechnologyInstructions1,
   properlyAndSuitablyEquippedInITToAccomplishCSNeeds1,
   increaseAccessSpeedRegionalOfficesToDL,
   improveQualityAssuranceTechnology,
   sensitiveToTheEnvironmentITEquipmentWillBeIntroducedTo,
   properlyAndSuitablyEquippedInITToAccomplishServiceGoals,
   decreaseClumsinessTechnology, costEffectiveTechnology,
   improveCallRecordingEquipment1,
   fitBetweenSystemCapabilitiesAndCSRequirements,
   properlyAndSuitablyEquippedInITToAccomplishCSNeeds,
   increaseITTrainingForCounsellors1, costEffectiveTraining,
   easilyAccessableTechnologyInstructions,
   supportAnalysisCounsellorsTime1, simpleTechnology1,
   increaseITMethodsToAcquireFeedback,
   adequatelyCustomizableCSTechnology, simpleTechnology,
   properlyAndSuitablyEquippedInITToAccomplishFundraisingNeeds,
   improveQualityAssuranceTechnology1,
   increasedEmphasisOnITInHiringProcessOfCounsellors,
   increaseAccessSpeedRegionalOfficesToDL1, keepUpWithNewTechnology,
   effectiveITTraining, decreaseClumsinessTechnology1,
   adjustToSoftwareChanges, considerationOfFeedbackITProviders,
   increaseITResources1, expandITDepartment,
   increasedEmphasisOnITInHiringProcessOfCounsellors1,
   increaseITResources, improveCallRecordingEquipment,
   considerationOfFeedbackFromCounsellors,
   increaseITTrainingForCounsellors, supportAnalysisCounsellorsTime,
   increaseITTrainingResources, increaseITMethodsToAcquireFeedback1
  ]).
types(task,
  [freeUpgrades, provideOnlineDonorTechnology,
   putContentOntoWebsite1, hardwareBeAcquiredForFree, useVPN,
   implementMaintainComputerSystemsForEmployeeUse, itResources,
   oracle, useOracleForDataBase, provideDocumentLibrarySystem1,
   manageAndImplementWebSite, provideCompiledCallData,
   payForUpgrades, feedbackFormSoftware, webServer,
   acquireUpgradesForFree, implementBulletinBoard1, freeWebServer,
   implementPhoneFeedback, implementCategorizationTool,
   feedbackFormBeImplemented, implementPhoneFeedback1,
   implementCategorizationTool1,
   provideTechnologyToCreateAndSendDocuments, networkPCs,
   getWebEventTechnology1, freeSoftware, payForSoftware,
   implementDirectorEnterpriseThroughBluePumpkin,
   implementActivityManager, implementIVR, useCurrentMethod,
   putContentOntoWebsite, implementEmailForCounsellors,
   acquireITResources, useT1, installDesktopSoftware,
   useInformalBuddySystemForTraining, acquireSoftwareForFree,
   freeHardware, implementAndManageTechnologyInRegionalOffices,
   acquireAndImplementEmployeeSoftware, donorAccountingDataBase,
   implementDesktops, telephonyBeImplementedAndManaged,
   implementSymposiumSystem, software, payForHardware,
   provideDocumentLibrarySystem, manageDonorAccountingDataBase,
   webServer1, implementEmailForCounsellors1, webSoftware,
   webCounsellingSoftwareBeImplemented, acquireWebServerForFree,
   hardware, upgrades, getWebEventTechnology, implementBulletinBoard,
   satisfyCSITNeeds, performDonorAccountingDataBaseMaintenance,
   acquireTelephoneSwitch, payForWebServer,
   provideOnlineDonorTechnology1,
   itDeptProvidesOrientationAndTraining
  ]).
aTrainingComputerBePresent <- [aTrainingComputerBePresent1].
acquireAndImplementEmployeeSoftware <-
  [ implementDirectorEnterpriseThroughBluePumpkin ].
acquireAndImplementEmployeeSoftware <- [implementActivityManager].
acquireAndImplementEmployeeSoftware <- [implementEmailForCounsellors].
acquireAndImplementEmployeeSoftware <- [implementCategorizationTool].
acquireAndImplementEmployeeSoftware <- [installDesktopSoftware].
acquireAndImplementEmployeeSoftware <-
  [ provideDocumentLibrarySystem1 ].
acquireAndImplementEmployeeSoftware <- [implementBulletinBoard].
acquireITResources <- [itResources].
acquireSoftware <- [acquireSoftwareForFree].
acquireSoftware <- [payForSoftware].
acquireSoftwareForFree <- [freeSoftware].
acquireTelephoneSwitch <- [hardwareBeAcquired].
acquireUpgradesForFree <- [freeUpgrades].
acquireWebServerForFree <- [freeWebServer].
anITTrainerBePresent <- [anITTrainerBePresent1].
callsBeRecordedIntoADataBase <- [callsBeRecordedIntoADataBase1].
considerationOfFeedbackITProviders <-
  [ considerationOfFeedbackFromCounsellors ].
decreaseClumsinessTechnology <- [decreaseClumsinessTechnology1].
donorAccountingDataBase <- [manageDonorAccountingDataBase].
easilyAccessableTechnologyInstructions <-
  [ easilyAccessableTechnologyInstructions1 ].
feedbackFormBeImplemented <- [acquireSoftware].
feedbackFormSoftware <- [feedbackFormBeImplemented].
getWebEventTechnology <- [acquireSoftware].
getWebEventTechnology1 <- [getWebEventTechnology].
hardwareBeAcquired <- [hardwareBeAcquiredForFree].
hardwareBeAcquired <- [payForHardware].
hardwareBeAcquiredForFree <- [freeHardware].
implementActivityManager <- [acquireSoftware].
implementAndManageTechnologyInRegionalOffices <- [useVPN].
implementAndManageTechnologyInRegionalOffices <-
  [ providePeerToPeerAccessRegionalOffices ].
implementBulletinBoard <- [acquireSoftware].
implementBulletinBoard1 <- [implementBulletinBoard].
implementCategorizationTool <- [acquireSoftware].
implementCategorizationTool1 <- [implementCategorizationTool].
implementDesktops <- [installDesktopSoftware].
implementDirectorEnterpriseThroughBluePumpkin <- [acquireSoftware].
implementEmailForCounsellors1 <- [implementEmailForCounsellors].
implementIVR <- [acquireSoftware].
implementMaintainComputerSystemsForEmployeeUse <-
  [ acquireAndImplementEmployeeSoftware ].
implementMaintainComputerSystemsForEmployeeUse <-
  [ implementAndManageTechnologyInRegionalOffices ].
implementMaintainComputerSystemsForEmployeeUse <-
  [ hardwareBeAcquired ].
implementMaintainComputerSystemsForEmployeeUse <- [networkPCs].
implementMaintainComputerSystemsForEmployeeUse <-
  [ provideTechnologyToCreateAndSendDocuments ].
implementMaintainComputerSystemsForEmployeeUse <- [implementDesktops].
implementPhoneFeedback <- [implementPhoneFeedback1].
implementSymposiumSystem <- [acquireSoftware].
improveCallRecordingEquipment <- [improveCallRecordingEquipment1].
improveQualityAssuranceTechnology <-
  [ improveQualityAssuranceTechnology1 ].
increaseAccessSpeedRegionalOfficesToDL <-
  [ increaseAccessSpeedRegionalOfficesToDL1 ].
increaseITMethodsToAcquireFeedback <-
  [ increaseITMethodsToAcquireFeedback1 ].
increaseITResources <- [increaseITResources1].
increaseITTrainingForCounsellors <-
  [ increaseITTrainingForCounsellors1 ].
increasedEmphasisOnITInHiringProcessOfCounsellors1 <-
  [ increasedEmphasisOnITInHiringProcessOfCounsellors ].
installDesktopSoftware <- [acquireSoftware].
integrateITSystems <-
  [ callCenterServerAndSchedulingSystemBeIntegrated ].
itBeUpgraded <- [payForUpgrades].
itDeptProvidesOrientationAndTraining <- [anITTrainerBePresent1].
itSystemsBeIntegrated <- [integrateITSystems].
itTrainingSupportBeGivenToEmployees <-
  [ itDeptProvidesOrientationAndTraining ].
itTrainingSupportBeGivenToEmployees <-
  [ useInformalBuddySystemForTraining ].
manageAndImplementWebSite <- [webCounsellingSoftwareBeImplemented].
manageAndImplementWebSite <- [provideOnlineDonorTechnology1].
manageAndImplementWebSite <- [getWebEventTechnology].
manageAndImplementWebSite <- [putContentOntoWebsite1].
manageAndImplementWebSite <- [webServerBeAcquired].
manageDonorAccountingDataBase <-
  [ performDonorAccountingDataBaseMaintenance ].
manageDonorAccountingDataBase <- [useOracleForDataBase].
payForHardware <- [hardware].
payForSoftware <- [software].
payForUpgrades <- [upgrades].
payForWebServer <- [webServer1].
performanceReviewInformationBeCollectedInDataBase <-
  [ performanceReviewInformationBeCollectedInDataBase1 ].
properlyAndSuitablyEquippedInITToAccomplishCSNeeds1 <-
  [ properlyAndSuitablyEquippedInITToAccomplishCSNeeds ].
provideCompiledCallData <- [implementCategorizationTool].
provideDocumentLibrarySystem <- [provideDocumentLibrarySystem1].
provideDocumentLibrarySystem1 <- [acquireSoftware].
provideOnlineDonorTechnology <- [provideOnlineDonorTechnology1].
providePeerToPeerAccessRegionalOffices <- [useCurrentMethod].
providePeerToPeerAccessRegionalOffices <- [useT1].
putContentOntoWebsite <- [putContentOntoWebsite1].
satisfyCSITNeeds <- [manageAndImplementWebSite].
satisfyCSITNeeds <- [telephonyBeImplementedAndManaged].
satisfyCSITNeeds <- [implementMaintainComputerSystemsForEmployeeUse].
satisfyCSITNeeds <- [manageDonorAccountingDataBase].
satisfyCSITNeeds <- [itTrainingSupportBeGivenToEmployees].
simpleTechnology <- [simpleTechnology1].
supportAnalysisCounsellorsTime <- [supportAnalysisCounsellorsTime1].
telephonyBeImplementedAndManaged <- [implementIVR].
telephonyBeImplementedAndManaged <- [acquireTelephoneSwitch].
telephonyBeImplementedAndManaged <- [implementSymposiumSystem].
telephonyBeImplementedAndManaged1 <-
  [ telephonyBeImplementedAndManaged ].
useOracleForDataBase <- [oracle].
webCounsellingSoftwareBeImplemented <- [webSoftwareBeAcquired].
webServer <- [webServerBeAcquired].
webServerBeAcquired <- [acquireWebServerForFree].
webServerBeAcquired <- [payForWebServer].
webSoftware <- [webSoftwareBeAcquired].
webSoftwareBeAcquired <- [payForSoftware].
webSoftwareBeAcquired <- [acquireSoftwareForFree].
adjustToSoftwareChanges <~ [hurt(itBeUpgraded)].
costEffectiveTechnology <~
  [ help(hardwareBeAcquiredForFree),
    help(acquireSoftwareForFree),
    hurt(payForHardware),
    hurt(useT1),
    hurt(payForSoftware),
    help(useCurrentMethod),
    help(useOracleForDataBase),
    help(acquireWebServerForFree),
    hurt(payForWebServer) ].
costEffectiveTraining <~
  [ hurt(aTrainingComputerBePresent1),
    help(useInformalBuddySystemForTraining),
    hurt(anITTrainerBePresent1) ].
effectiveITTraining <~
  [ help(increasedEmphasisOnITInHiringProcessOfCounsellors1),
    help(aTrainingComputerBePresent1),
    help(itDeptProvidesOrientationAndTraining),
    help(increaseITTrainingResources) ].
expandITDepartment <~
  [ make(increaseITResources),
    help(costEffectiveTechnology) ].
fitBetweenSystemCapabilitiesAndCSRequirements <~
  [ help(adequatelyCustomizableCSTechnology) ].
improveQualityAssuranceTechnology1 <~
  [ help(increaseITMethodsToAcquireFeedback1),
    help(performanceReviewInformationBeCollectedInDataBase1),
    help(callsBeRecordedIntoADataBase1),
    help(improveCallRecordingEquipment1) ].
increaseAccessSpeedRegionalOfficesToDL1 <~ [make(useT1)].
increaseITMethodsToAcquireFeedback1 <~
  [ help(feedbackFormBeImplemented) ].
increaseITResources <~ [help(costEffectiveTraining)].
increaseITTrainingForCounsellors1 <~
  [ help(increaseITTrainingResources),
    help(aTrainingComputerBePresent1),
    help(anITTrainerBePresent1) ].
increaseITTrainingResources <~
  [ help(expandITDepartment),
    help(increaseITResources),
    help(costEffectiveTechnology) ].
keepUpWithNewTechnology <~
  [ help(increaseITResources),
    help(itBeUpgraded),
    hurt(csBeNotForProfit) ].
properlyAndSuitablyEquippedInITToAccomplishCSNeeds <~
  [ help(properlyAndSuitablyEquippedInITToAccomplishFundraisingNeeds),
    help(effectiveITTraining),
    help(acquireITResources),
    help(fitBetweenSystemCapabilitiesAndCSRequirements),
    help(adjustToSoftwareChanges),
    help(properlyAndSuitablyEquippedInITToAccomplishServiceGoals),
    help(itBeUpgraded),
    help(sensitiveToTheEnvironmentITEquipmentWillBeIntroducedTo),
    help(keepUpWithNewTechnology) ].
properlyAndSuitablyEquippedInITToAccomplishFundraisingNeeds <~
  [ help(provideDocumentLibrarySystem1),
    help(manageDonorAccountingDataBase) ].
properlyAndSuitablyEquippedInITToAccomplishServiceGoals <~
  [ help(implementEmailForCounsellors),
    help(installDesktopSoftware),
    hurt(implementDirectorEnterpriseThroughBluePumpkin),
    help(implementBulletinBoard),
    hurt(implementBulletinBoard),
    help(implementActivityManager),
    hurt(implementActivityManager),
    help(implementCategorizationTool),
    help(considerationOfFeedbackFromCounsellors),
    help(implementPhoneFeedback1) ].
sensitiveToTheEnvironmentITEquipmentWillBeIntroducedTo <~
  [ help(itProvidersHaveKnowledgeOfCounselling),
    help(itProvidersHaveKnowledgeOfFundraisingAndMarketing) ].
simpleTechnology1 <~ [help(integrateITSystems)].
supportAnalysisCounsellorsTime1 <~
  [ help(implementDirectorEnterpriseThroughBluePumpkin),
    help(implementActivityManager) ].
