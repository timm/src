% CSFDandMarketing  (nfr2 dialect: <- rules, <~ contribution lists)
:- discontiguous (<-)/2, (<~)/2.
:- dynamic (<-)/2, (<~)/2.
types(goal,
  [counselorsAttendFundraisingEvents, contributeToACause,
   receiptBeProvided, pledgesBeCollected, projectDeadlinesBeMet1,
   sponsorsForEventsBeFound, marketingFromGovernmentBeAcquired,
   sponsorsMarketingChannelsBeUsed,
   companyRelationshipBeRetainedAfterMergers,
   notForProfitPartnersBeInvolvedInEvents, staffBeSupported,
   singleCharitableRegistrationNumberBeUsed, contributionBeMade,
   fundsBeRaised, makeContributionToCharity, projectDeadlinesBeMet,
   involveNotForProfitPartnersInEvents,
   marketingBeMadeUsingDedicatedCounselor, eventsBeMarketed,
   beInformedOfFundraisingEvents, answersBeProvidedToMediaQueries,
   counselorsWhoWantAPublicVoiceBeTrained,
   informationBeSharedWithSponsors,
   maintain20CostsAgainstRevenuesRatio,
   corporatePartnerFundraisingExpectationsBeKnown,
   corporatePartnerMarketingExpectationsBeKnown,
   periodicalCommunicationWithRegionalStaffBeMaintained,
   sponsorRelationshipsBeManaged,
   frontEndForIncomeRecordingBeSupported,
   corporatePartnerExpectationsBeSharedWithStaff,
   servicesBeProvidedForKidsBullyingLine, donorInformationBeRecorded
  ]).
types(softgoal,
  [sponsorshipBeBeneficial, marketFundraisingEvents2,
   acquireNCSStories, upToDateCorporatePartnerInformation,
   regionalStaffFeelIncluded, proactiveMediaRelationship,
   csNServices, highResponseIndividualDonors,
   accountabilityOfServices1, happinessStaff, csStories,
   exclusiveRelationshipsOfficialPartners, reachMoreKidsSponsors,
   followHighestEthicalGuidelines,
   reduceInternalCommunicationConfusion,
   commitmentToCSCauseFromSponsorsEmployees,
   presentProposalConvincinglyToSponsors, successfulEvents,
   goodMediaExposure, quickResponseToQuestionsAndConcerns,
   positiveInternalOpinion, credibilityCSBrand,
   engageEmployeesInEvents1, sponsorPartnerNcontacts2,
   presentationSkills1, recognition, credibilityCSBrand2,
   sponsorPartnerNcontacts, createLifeLongVolunteerSpirit1,
   acquirePublicSpeakingSkills, increaseAwareness,
   engagementStudentAmbassadorsInPromotingAwareness,
   responsibleUsageSponsorFunds, happinessStaff3,
   highResponseIndividualDonors1, avoidOverMarketingServices,
   engagementSponsorsInTheCauseOfCS, positiveReputation,
   nationalEventCalendar, involvementNotForProfitPartnersInEvents,
   engagementOfSponsorEmployeesInFundDevelopment,
   credibilityCSBrand1, exclusiveRelationshipsOfficialPartners1,
   quickResponseToSponsors1, appearAsGoodCorporateCitizens,
   engageEmployeesInEvents, goodProjectManagement, cobranding,
   matchFundraisingTargets, marketCSBrand, longTermFunding,
   improveImageToKids, acquireGovernmentFunding,
   marketFundraisingEvents1, engageEmployeesInFundraisingEvents,
   meetCorporateSponsorsNeeds, trustOfSponsorsTowardsCS2,
   contributeToAGoodCause, increaseVolunteers1,
   agreementStaffOverCorporatePartnerExpectations,
   matchFundraisingTargets2,
   engagementSponsorEmployeesInPromotingAwareness1,
   projectManagementSkills, positiveInternalOpinion1,
   retainSponsors1, upToDateInformationOnPrograms1,
   increasedInvolvementCounselorsInEvents,
   uniteVolunteersAndSponsors, goodProjectManagement2,
   presentationSkills, qualityServices1,
   increasedInvolvementCounselorsInEvents1,
   corporateSponsorsFeelIncluded, recognizeNSponsorContribution1,
   happinessStaff1, quickResponseToSponsors,
   increaseConnectionCounselorsAndCommunity, timelyServices,
   longTermFunding1, retainSponsors2, experiencedMarketingPartners,
   regionalStaffFeelIncluded1, recognizeNSponsorContribution,
   qualityServices, responsibleUsageSponsorFunds2,
   involvementNotForProfitPartnersInEvents1,
   increaseAccessSpeedRegionalOfficesToDocumentLibrary,
   increasedAvailabilityToSponsors, accountabilityOfServices,
   highResponseIndividualDonors2, happinessStaff2,
   increaseFreeServices, trustOfDonor, positiveImageToEmployees,
   recognizeNSponsorContribution2,
   engagementSponsorEmployeesInPromotingAwareness2,
   includeCorporatePartnersInTheDevelopmentOfPressReleases,
   followHighestEthicalGuidelines1, contributeToAGoodCause1,
   trustOfSponsorsTowardsCS1, increasePhilanthropicDonations,
   increasedInteractionCounselorsWithMedia, sponsorPartnerNcontacts1,
   provincialGovernment, responsibleUsageSponsorFunds1,
   minimizeExpenses, accountabilityOfServices2, marketPHLBrand,
   improveImageToKids1, increaseAwareness1,
   upToDateInformationOnPrograms, increaseNAwareness,
   increaseAwareness2, regionalStaffFeelIncluded2,
   increaseInvolvementSponsorsInPuttingOnEvents,
   exclusiveRelationshipsOfficialPartners2, acquireFreeServices,
   marketFundraisingEvents, timelyProvisionOfFreeServices1,
   successfulMarketingCampaign,
   engagementOfSponsorEmployeesInFundDevelopment1,
   corporateSponsorFeelIncluded, followHighestEthicalGuidelines2,
   engageEmployeesInEvents2, demonstrableServices1,
   increasedAvailabilityCounselorsToPublicSponsors,
   availabilityForAdministrationAndAccountingPurposesAcrossCS,
   publishedCSStories, attractSponsors1, attractSponsors,
   increaseVolunteers, upToDateCorporatePartnerInformation2,
   engagementSponsorEmployeesInPromotingAwareness,
   timelyProvisionOfFreeServices,
   engageEmployeesInPromotingAwareness, demonstrableServices,
   attractEventParticipants, hearCSStories,
   createLifeLongVolunteerSpirit, minimizeCostOfEvents,
   trustOfSponsorsTowardsCS, retainSponsors,
   experiencedMarketingPartners2, demonstrableServices2,
   engagementStudentAmbassadorsInPromotingAwareness1,
   qualityServices2, positiveReputationOfCS,
   upToDateInformationOnCorporateSponsors,
   positiveAssociationNByConsumers, attractSponsors2,
   positiveReputationOfCS2, inspiredStaff,
   increasedCorporateSponsorFunds, avoidOverMarketingServices1
  ]).
types(task,
  [provideOnlineDonorTechnology, manageNprojects,
   bringRegionalFundraisingStaffTogetherOnceAYear,
   recordDonorInformation,
   providePromotionalMaterialToStudentAmbassadors, contributeOnline,
   conflictsBeManaged, manageProjects, attendFundraisingEvent,
   useVolunteerServices, sponsorshipProposal,
   provideCompiledCallData, payFundDevelopmentAndMarketingStaff,
   useSponsorMarketingChannels, getCorporatePartnerInformationFromDL,
   manageReceivables, becomeAMajorPatron, createThankYouAds,
   reachAgreement, getWebEventTechnology1, provideMoneyForServices,
   collectDonationsOnline,
   createPostersFlyersAndInformationalMaterial,
   provideDocumentLibrarySystem, elaborateFundraisingTargets,
   becomeAPatron, becomeAOfficialPartner, providePartnerContactsToCS,
   createBrandedProducts, runFundraiserInSchools,
   reallocateResources, saGiveCSPresentations,
   putOnFundraisingWebEvents, elaborateFundraisingTargets1,
   giveCSPresentations, speakAtFundraisers,
   getCorporatePartnerInformationFromDocumentLibrary1, agreement,
   singleCharitableRegistrationNumber, informSponsorsOfProgress,
   getDonorDatabase, freeAdvertisement, useSponsorLogo,
   implementStayInTouchProgram, reallocateResources1,
   putOnOrientationProcessForFundDevelopmentAndMarketingStaff,
   organizeDiscussionsWithSponsors,
   providePAPToStaffNUsingTheDocumentLibrary,
   provideCompiledCallDataToMedia, nationalMarketingStrategy,
   freeServices, getPAPInformation1, provideFundraisingServices,
   getDonorAccountingDatabase, collectPledgeOnline,
   collectDonorInformation, getSponsorshipProposal,
   writeArticlesForWebsite1, provideFreeServices, manageAccounts1,
   workWithTheRegionsToImplementEvents, createGeneralLedgers1,
   getSponsorsForEvents, putOnFundraisingEvents,
   donorAccountingDatabase, getWebTechnology, marketCSService,
   reachAgreement1, provideLogoToCS, sharePAPInDocumentLibrary,
   getCorporatePartnerInformationFromDL1,
   sponsorsIncludeCSLogosAndDescriptionsOnTheirProducts,
   biWeeklyConferenceCalls, givePhilanthropicDonation,
   writeArticlesForMagazines, exclusiveBrandAndLogoUse,
   putOnFundraisingEventsOnTheWeb, saRunFundraiserInSchools,
   collectPledgeDuringEvent, getCorporateSponsorFunds, managePAP,
   createGeneralLedgers, developExternalComunications,
   saSpeakAtFundraisers, eventCoordination,
   getCorporatePartnerInformationFromDocumentLibrary,
   collectPledgeOnline2, promotionResources, manageReceivables1,
   provideFreeServices1, placeSponsorLogosInEvents,
   getPAPInformation, pledgeNonline, sharePAPInDocumentLibrary1,
   storeDonorTransactionsIntoDatabase, trackBudgets, pledgeOnline,
   emailCorporatePartnersInterestingAndRelevantNewsPieces,
   sendRecognitionLetters, philanthropicDonations,
   manageNPartnerRelationship, writeArticlesForWebsite,
   singleCharitableRegistrationNumber1,
   pitchToNationalCorporateSponsorsTheSponsorshipOfRegionalEvents,
   providePhilanthropicDonation, pledgeNDuringEvent,
   grantExclusiveUseOfBrandAndLogo,
   putTogetherProposalsForCorporateSponsors,
   manageNPartnerRelationship1, communicateWithHeadOffice,
   subscribeToDocumentLibraryFolders2,
   counselorSpeakOnKidsIssuesInGeneral1, provideRealTimeTaxReceipts,
   provideReceipts, useNationalEventCalendar, collectPledgeOnline3,
   funds, subscribeToDocumentLibraryFolders, getWebEventTechnology,
   putOnOrientationForVolunteers,
   writeDownCorporateSponsorsObjectives, getDonorTechnology,
   sponsorLogo, developNationalEventCalendar, provideFunds1,
   manageAccounts, counselorSpeakOnKidsIssuesInGeneral,
   communicateThroughInternetAndPhone, provideFunds,
   pledgeNDuringEvent1, subscribeToDocumentLibraryFolders1,
   marketOnlyForSeriousIssues, trainCounselorsOnPublicSpeaking,
   writeArticlesForMagazines1, storeDonorInformationIntoDatabase,
   getFreeAdvertisement, marketThroughOwnChannels,
   getPhilanthropicDonations, useFreeServices, participateInEvents
  ]).
accountabilityOfServices <- [accountabilityOfServices1].
accountabilityOfServices2 <- [accountabilityOfServices1].
acquireFreeServices <- [provideFreeServices1].
acquireGovernmentFunding <- [provideMoneyForServices].
acquireNCSStories <- [csStories].
acquirePublicSpeakingSkills <- [trainCounselorsOnPublicSpeaking].
agreement <- [reachAgreement].
attendFundraisingEvent <- [pledgeNDuringEvent].
attendFundraisingEvent <- [beInformedOfFundraisingEvents].
attractSponsors <- [attractSponsors1].
attractSponsors1 <- [attractSponsors2].
avoidOverMarketingServices1 <- [avoidOverMarketingServices].
beInformedOfFundraisingEvents <- [marketFundraisingEvents2].
becomeAMajorPatron <- [getSponsorshipProposal].
becomeAMajorPatron <- [reachAgreement1].
becomeAMajorPatron <- [makeContributionToCharity].
becomeAOfficialPartner <- [reachAgreement1].
becomeAOfficialPartner <- [makeContributionToCharity].
becomeAOfficialPartner <- [getSponsorshipProposal].
becomeAPatron <- [reachAgreement1].
becomeAPatron <- [makeContributionToCharity].
becomeAPatron <- [getSponsorshipProposal].
cobranding <- [exclusiveBrandAndLogoUse].
collectDonationsOnline <- [provideRealTimeTaxReceipts].
collectDonationsOnline <- [collectPledgeOnline2].
collectPledgeDuringEvent <- [pledgeNDuringEvent1].
collectPledgeOnline <- [collectPledgeOnline3].
collectPledgeOnline2 <- [pledgeOnline].
collectPledgeOnline3 <- [collectPledgeOnline2].
communicateWithHeadOffice <-
  [ periodicalCommunicationWithRegionalStaffBeMaintained ].
companyRelationshipBeRetainedAfterMergers <-
  [ manageNPartnerRelationship ].
contributeOnline <- [beInformedOfFundraisingEvents].
contributeOnline <- [pledgeNonline].
contributeOnline <- [receiptBeProvided].
contributeToACause <- [becomeAMajorPatron].
contributeToACause <- [becomeAOfficialPartner].
contributeToACause <- [becomeAPatron].
contributionBeMade <- [givePhilanthropicDonation].
contributionBeMade <- [contributeOnline].
contributionBeMade <- [attendFundraisingEvent].
corporatePartnerExpectationsBeSharedWithStaff <-
  [ providePAPToStaffNUsingTheDocumentLibrary ].
corporatePartnerFundraisingExpectationsBeKnown <-
  [ getCorporatePartnerInformationFromDocumentLibrary ].
corporatePartnerMarketingExpectationsBeKnown <-
  [ getCorporatePartnerInformationFromDocumentLibrary1 ].
counselorSpeakOnKidsIssuesInGeneral <-
  [ counselorSpeakOnKidsIssuesInGeneral1 ].
counselorsAttendFundraisingEvents <- [participateInEvents].
counselorsWhoWantAPublicVoiceBeTrained <-
  [ trainCounselorsOnPublicSpeaking ].
createGeneralLedgers1 <- [createGeneralLedgers].
createLifeLongVolunteerSpirit1 <- [createLifeLongVolunteerSpirit].
credibilityCSBrand <- [credibilityCSBrand1].
credibilityCSBrand2 <- [credibilityCSBrand1].
demonstrableServices <- [demonstrableServices1].
demonstrableServices1 <- [csNServices].
demonstrableServices2 <- [demonstrableServices1].
developExternalComunications <- [createBrandedProducts].
developExternalComunications <-
  [ createPostersFlyersAndInformationalMaterial ].
developExternalComunications <-
  [ providePromotionalMaterialToStudentAmbassadors ].
donorInformationBeRecorded <- [recordDonorInformation].
elaborateFundraisingTargets <- [elaborateFundraisingTargets1].
engageEmployeesInEvents <-
  [ engagementOfSponsorEmployeesInFundDevelopment ].
engageEmployeesInEvents1 <-
  [ engagementOfSponsorEmployeesInFundDevelopment,
    engageEmployeesInEvents2 ].
engageEmployeesInFundraisingEvents <- [engageEmployeesInEvents].
engageEmployeesInPromotingAwareness <-
  [ engagementSponsorEmployeesInPromotingAwareness2 ].
engagementOfSponsorEmployeesInFundDevelopment1 <-
  [ engagementOfSponsorEmployeesInFundDevelopment ].
engagementSponsorEmployeesInPromotingAwareness <-
  [ engagementSponsorEmployeesInPromotingAwareness1 ].
engagementSponsorEmployeesInPromotingAwareness2 <-
  [ engagementSponsorEmployeesInPromotingAwareness ].
engagementStudentAmbassadorsInPromotingAwareness <-
  [ engagementStudentAmbassadorsInPromotingAwareness1 ].
eventCoordination <- [workWithTheRegionsToImplementEvents].
eventsBeMarketed <- [marketFundraisingEvents].
exclusiveRelationshipsOfficialPartners <-
  [ exclusiveRelationshipsOfficialPartners1 ].
exclusiveRelationshipsOfficialPartners1 <-
  [ exclusiveRelationshipsOfficialPartners2 ].
experiencedMarketingPartners <- [experiencedMarketingPartners2].
followHighestEthicalGuidelines <- [followHighestEthicalGuidelines1].
followHighestEthicalGuidelines2 <- [followHighestEthicalGuidelines1].
freeServices <- [provideFreeServices1, provideFreeServices].
frontEndForIncomeRecordingBeSupported <-
  [ storeDonorTransactionsIntoDatabase ].
frontEndForIncomeRecordingBeSupported <- [manageReceivables].
frontEndForIncomeRecordingBeSupported <- [manageAccounts].
frontEndForIncomeRecordingBeSupported <- [createGeneralLedgers].
funds <- [fundsBeRaised].
fundsBeRaised <- [putOnFundraisingEventsOnTheWeb].
fundsBeRaised <- [putOnFundraisingEvents].
fundsBeRaised <- [saRunFundraiserInSchools].
getCorporatePartnerInformationFromDL <-
  [ getCorporatePartnerInformationFromDL1 ].
getCorporatePartnerInformationFromDocumentLibrary <-
  [ getPAPInformation1 ].
getCorporatePartnerInformationFromDocumentLibrary <-
  [ subscribeToDocumentLibraryFolders2 ].
getCorporatePartnerInformationFromDocumentLibrary1 <-
  [ getPAPInformation ].
getCorporatePartnerInformationFromDocumentLibrary1 <-
  [ subscribeToDocumentLibraryFolders1 ].
getCorporateSponsorFunds <- [provideFunds1].
getDonorAccountingDatabase <-
  [ donorAccountingDatabase,
    getDonorDatabase ].
getDonorTechnology <- [provideOnlineDonorTechnology].
getFreeAdvertisement <- [freeAdvertisement].
getPAPInformation <- [sharePAPInDocumentLibrary1].
getPAPInformation1 <- [sharePAPInDocumentLibrary1].
getSponsorsForEvents <- [reachAgreement].
getSponsorshipProposal <- [sponsorshipProposal].
getWebEventTechnology <- [getWebEventTechnology1].
getWebTechnology <- [getWebEventTechnology].
goodProjectManagement <- [projectManagementSkills].
goodProjectManagement2 <- [projectManagementSkills].
grantExclusiveUseOfBrandAndLogo <- [exclusiveBrandAndLogoUse].
happinessStaff1 <- [happinessStaff2].
happinessStaff2 <- [happinessStaff].
happinessStaff3 <- [happinessStaff].
hearCSStories <- [publishedCSStories].
highResponseIndividualDonors1 <-
  [ highResponseIndividualDonors2,
    highResponseIndividualDonors ].
improveImageToKids1 <- [improveImageToKids].
increaseAwareness1 <- [increaseAwareness].
increaseNAwareness <- [increaseAwareness2].
increaseVolunteers <- [increaseVolunteers1].
increasedAvailabilityCounselorsToPublicSponsors <-
  [ increasedAvailabilityToSponsors ].
informationBeSharedWithSponsors <- [informSponsorsOfProgress].
informationBeSharedWithSponsors <-
  [ emailCorporatePartnersInterestingAndRelevantNewsPieces ].
involveNotForProfitPartnersInEvents <-
  [ notForProfitPartnersBeInvolvedInEvents ].
involvementNotForProfitPartnersInEvents <-
  [ involvementNotForProfitPartnersInEvents1 ].
longTermFunding1 <- [longTermFunding].
maintain20CostsAgainstRevenuesRatio <- [useFreeServices].
maintain20CostsAgainstRevenuesRatio <- [useVolunteerServices].
makeContributionToCharity <- [provideFunds].
makeContributionToCharity <- [marketThroughOwnChannels].
makeContributionToCharity <- [providePhilanthropicDonation].
makeContributionToCharity <- [provideFreeServices].
manageAccounts1 <- [manageAccounts].
manageNPartnerRelationship <- [informationBeSharedWithSponsors].
manageNPartnerRelationship <- [managePAP].
manageNPartnerRelationship1 <- [manageNPartnerRelationship].
manageNprojects <- [reallocateResources].
manageNprojects <- [timelyProvisionOfFreeServices1].
manageNprojects <- [trackBudgets].
managePAP <- [putTogetherProposalsForCorporateSponsors].
managePAP <- [useNationalEventCalendar].
managePAP <-
  [ pitchToNationalCorporateSponsorsTheSponsorshipOfRegionalEvents ].
managePAP <- [reachAgreement].
managePAP <- [writeDownCorporateSponsorsObjectives].
managePAP <- [presentProposalConvincinglyToSponsors].
managePAP <- [organizeDiscussionsWithSponsors].
manageProjects <- [timelyProvisionOfFreeServices].
manageProjects <- [nationalMarketingStrategy].
manageProjects <- [reallocateResources1].
manageReceivables1 <- [manageReceivables].
marketCSService <- [provincialGovernment].
marketFundraisingEvents <- [marketFundraisingEvents1].
marketFundraisingEvents2 <- [marketFundraisingEvents1].
marketingBeMadeUsingDedicatedCounselor <- [writeArticlesForWebsite].
marketingBeMadeUsingDedicatedCounselor <-
  [ counselorSpeakOnKidsIssuesInGeneral ].
marketingBeMadeUsingDedicatedCounselor <- [writeArticlesForMagazines].
marketingFromGovernmentBeAcquired <- [marketCSService].
matchFundraisingTargets2 <- [matchFundraisingTargets].
nationalEventCalendar <- [developNationalEventCalendar].
periodicalCommunicationWithRegionalStaffBeMaintained <-
  [ biWeeklyConferenceCalls ].
periodicalCommunicationWithRegionalStaffBeMaintained <-
  [ communicateThroughInternetAndPhone ].
periodicalCommunicationWithRegionalStaffBeMaintained <-
  [ bringRegionalFundraisingStaffTogetherOnceAYear ].
philanthropicDonations <-
  [ getPhilanthropicDonations,
    givePhilanthropicDonation,
    providePhilanthropicDonation ].
pledgeNDuringEvent1 <- [pledgeNDuringEvent].
pledgeOnline <- [pledgeNonline].
pledgesBeCollected <- [collectPledgeOnline].
pledgesBeCollected <- [collectPledgeDuringEvent].
positiveInternalOpinion <- [positiveInternalOpinion1].
positiveReputation <- [positiveReputationOfCS].
positiveReputationOfCS2 <- [positiveReputationOfCS].
presentationSkills <- [presentationSkills1].
projectDeadlinesBeMet <- [manageNprojects].
projectDeadlinesBeMet1 <- [manageProjects].
promotionResources <-
  [ providePromotionalMaterialToStudentAmbassadors ].
provideCompiledCallDataToMedia <- [provideCompiledCallData].
provideFundraisingServices <- [useVolunteerServices].
provideFunds1 <- [provideFunds].
providePAPToStaffNUsingTheDocumentLibrary <-
  [ subscribeToDocumentLibraryFolders ].
providePAPToStaffNUsingTheDocumentLibrary <-
  [ sharePAPInDocumentLibrary ].
providePartnerContactsToCS <- [sponsorPartnerNcontacts].
provideReceipts <- [provideRealTimeTaxReceipts].
provincialGovernment <- [servicesBeProvidedForKidsBullyingLine].
publishedCSStories <- [acquireNCSStories].
putOnFundraisingEvents <- [collectPledgeDuringEvent].
putOnFundraisingEvents <- [maintain20CostsAgainstRevenuesRatio].
putOnFundraisingEvents <- [sponsorsForEventsBeFound].
putOnFundraisingEvents <- [developNationalEventCalendar].
putOnFundraisingEvents <- [eventsBeMarketed].
putOnFundraisingEventsOnTheWeb <- [getDonorAccountingDatabase].
putOnFundraisingEventsOnTheWeb <- [getWebEventTechnology].
putOnFundraisingEventsOnTheWeb <- [getDonorTechnology].
putOnFundraisingEventsOnTheWeb <- [collectPledgeOnline].
putOnFundraisingEventsOnTheWeb <-
  [ maintain20CostsAgainstRevenuesRatio ].
putOnFundraisingEventsOnTheWeb <- [eventsBeMarketed].
putOnFundraisingWebEvents <- [collectDonationsOnline].
putOnFundraisingWebEvents <- [getWebTechnology].
qualityServices1 <- [qualityServices].
qualityServices2 <- [qualityServices].
quickResponseToQuestionsAndConcerns <- [quickResponseToSponsors1].
quickResponseToSponsors1 <- [quickResponseToSponsors].
reachAgreement1 <- [agreement].
receiptBeProvided <- [provideReceipts].
recognition <- [recognizeNSponsorContribution].
recognizeNSponsorContribution <- [recognizeNSponsorContribution2].
recognizeNSponsorContribution1 <- [recognizeNSponsorContribution].
recordDonorInformation <- [storeDonorTransactionsIntoDatabase].
recordDonorInformation <- [collectDonorInformation].
recordDonorInformation <- [storeDonorInformationIntoDatabase].
recordDonorInformation <- [getDonorDatabase].
regionalStaffFeelIncluded1 <- [regionalStaffFeelIncluded2].
regionalStaffFeelIncluded2 <- [regionalStaffFeelIncluded].
responsibleUsageSponsorFunds <- [responsibleUsageSponsorFunds1].
responsibleUsageSponsorFunds2 <- [responsibleUsageSponsorFunds1].
retainSponsors <- [retainSponsors2].
saGiveCSPresentations <- [giveCSPresentations].
saRunFundraiserInSchools <- [runFundraiserInSchools].
saSpeakAtFundraisers <- [speakAtFundraisers].
singleCharitableRegistrationNumber <-
  [ singleCharitableRegistrationNumber1 ].
singleCharitableRegistrationNumberBeUsed <-
  [ singleCharitableRegistrationNumber ].
sponsorLogo <- [provideLogoToCS].
sponsorPartnerNcontacts <- [sponsorPartnerNcontacts1].
sponsorRelationshipsBeManaged <- [manageNPartnerRelationship1].
sponsorsForEventsBeFound <- [getSponsorsForEvents].
sponsorsMarketingChannelsBeUsed <-
  [ sponsorsIncludeCSLogosAndDescriptionsOnTheirProducts ].
sponsorshipProposal <- [presentProposalConvincinglyToSponsors].
staffBeSupported <- [implementStayInTouchProgram].
staffBeSupported <-
  [ putOnOrientationProcessForFundDevelopmentAndMarketingStaff ].
staffBeSupported <- [putOnOrientationForVolunteers].
subscribeToDocumentLibraryFolders <- [provideDocumentLibrarySystem].
subscribeToDocumentLibraryFolders1 <- [provideDocumentLibrarySystem].
subscribeToDocumentLibraryFolders2 <- [provideDocumentLibrarySystem].
timelyProvisionOfFreeServices <- [timelyServices].
trustOfSponsorsTowardsCS1 <- [trustOfSponsorsTowardsCS].
trustOfSponsorsTowardsCS2 <- [trustOfSponsorsTowardsCS1].
upToDateInformationOnCorporateSponsors <-
  [ upToDateCorporatePartnerInformation2 ].
upToDateInformationOnPrograms <- [upToDateInformationOnPrograms1].
upToDateInformationOnPrograms1 <-
  [ upToDateCorporatePartnerInformation ].
useFreeServices <- [freeServices].
useNationalEventCalendar <- [nationalEventCalendar].
useSponsorLogo <- [sponsorLogo].
useSponsorMarketingChannels <- [marketThroughOwnChannels].
writeArticlesForMagazines <- [writeArticlesForMagazines1].
writeArticlesForWebsite <- [writeArticlesForWebsite1].
acquireFreeServices <~
  [ help(attractSponsors2),
    help(sponsorPartnerNcontacts2) ].
agreementStaffOverCorporatePartnerExpectations <~
  [ help(periodicalCommunicationWithRegionalStaffBeMaintained),
    help(getCorporatePartnerInformationFromDL) ].
appearAsGoodCorporateCitizens <~
  [ help(recognition),
    help(recognition),
    help(cobranding) ].
attractEventParticipants <~
  [ help(increaseNAwareness),
    help(eventsBeMarketed),
    help(positiveReputation) ].
attractSponsors <~
  [ help(increasedAvailabilityCounselorsToPublicSponsors),
    help(sponsorPartnerNcontacts1) ].
attractSponsors2 <~
  [ help(useSponsorLogo),
    help(goodMediaExposure),
    help(sponsorPartnerNcontacts2),
    help(sponsorPartnerNcontacts2),
    help(successfulMarketingCampaign) ].
availabilityForAdministrationAndAccountingPurposesAcrossCS <~
  [ help(frontEndForIncomeRecordingBeSupported),
    help(donorInformationBeRecorded) ].
avoidOverMarketingServices <~ [make(marketOnlyForSeriousIssues)].
cobranding <~ [help(provideLogoToCS), make(becomeAOfficialPartner)].
commitmentToCSCauseFromSponsorsEmployees <~
  [ help(engageEmployeesInFundraisingEvents),
    help(engageEmployeesInPromotingAwareness) ].
contributeToAGoodCause <~ [help(trustOfSponsorsTowardsCS)].
contributeToAGoodCause1 <~ [help(trustOfDonor)].
corporateSponsorFeelIncluded <~
  [ help(upToDateInformationOnPrograms),
    help(quickResponseToQuestionsAndConcerns) ].
corporateSponsorsFeelIncluded <~
  [ make(meetCorporateSponsorsNeeds),
    help(informationBeSharedWithSponsors) ].
engagementOfSponsorEmployeesInFundDevelopment <~
  [ help(attractEventParticipants),
    help(increaseInvolvementSponsorsInPuttingOnEvents) ].
engagementSponsorsInTheCauseOfCS <~
  [ help(meetCorporateSponsorsNeeds),
    help(commitmentToCSCauseFromSponsorsEmployees) ].
exclusiveRelationshipsOfficialPartners <~
  [ make(becomeAOfficialPartner) ].
getFreeAdvertisement <~ [help(sponsorPartnerNcontacts2)].
goodMediaExposure <~
  [ help(answersBeProvidedToMediaQueries),
    help(proactiveMediaRelationship) ].
goodProjectManagement <~ [help(manageProjects)].
goodProjectManagement2 <~ [help(manageNprojects)].
happinessStaff <~
  [ help(regionalStaffFeelIncluded1),
    help(conflictsBeManaged),
    help(payFundDevelopmentAndMarketingStaff),
    help(positiveInternalOpinion),
    help(staffBeSupported) ].
highResponseIndividualDonors <~
  [ help(increaseConnectionCounselorsAndCommunity) ].
highResponseIndividualDonors2 <~
  [ help(increasedInvolvementCounselorsInEvents1) ].
improveImageToKids <~
  [ help(saSpeakAtFundraisers),
    help(saGiveCSPresentations),
    help(developExternalComunications),
    help(successfulMarketingCampaign) ].
increaseAwareness <~
  [ help(marketPHLBrand),
    help(saSpeakAtFundraisers),
    help(goodMediaExposure),
    help(saGiveCSPresentations) ].
increaseConnectionCounselorsAndCommunity <~
  [ help(increasedInvolvementCounselorsInEvents) ].
increaseFreeServices <~ [help(sponsorPartnerNcontacts1)].
increaseInvolvementSponsorsInPuttingOnEvents <~
  [ make(sponsorsForEventsBeFound),
    help(sponsorRelationshipsBeManaged) ].
increasePhilanthropicDonations <~
  [ help(highResponseIndividualDonors2),
    help(getPhilanthropicDonations) ].
increaseVolunteers <~
  [ help(createLifeLongVolunteerSpirit1),
    help(uniteVolunteersAndSponsors) ].
increasedAvailabilityCounselorsToPublicSponsors <~
  [ help(increasedInvolvementCounselorsInEvents1) ].
increasedCorporateSponsorFunds <~
  [ help(getCorporateSponsorFunds),
    help(attractSponsors),
    help(increaseInvolvementSponsorsInPuttingOnEvents) ].
increasedInteractionCounselorsWithMedia <~
  [ help(counselorsWhoWantAPublicVoiceBeTrained),
    help(counselorSpeakOnKidsIssuesInGeneral) ].
increasedInvolvementCounselorsInEvents <~
  [ help(counselorSpeakOnKidsIssuesInGeneral) ].
increasedInvolvementCounselorsInEvents1 <~
  [ help(counselorsAttendFundraisingEvents) ].
inspiredStaff <~
  [ help(increasedInvolvementCounselorsInEvents1),
    help(elaborateFundraisingTargets),
    help(happinessStaff3) ].
longTermFunding <~ [help(retainSponsors)].
marketCSBrand <~
  [ help(engagementSponsorEmployeesInPromotingAwareness),
    help(successfulMarketingCampaign),
    help(experiencedMarketingPartners),
    help(sponsorsMarketingChannelsBeUsed),
    help(positiveReputationOfCS2) ].
marketFundraisingEvents1 <~
  [ help(saSpeakAtFundraisers),
    help(proactiveMediaRelationship),
    help(developExternalComunications),
    help(projectDeadlinesBeMet1) ].
marketPHLBrand <~
  [ help(getFreeAdvertisement),
    help(successfulMarketingCampaign),
    help(experiencedMarketingPartners),
    help(sponsorsMarketingChannelsBeUsed),
    help(positiveReputationOfCS2) ].
matchFundraisingTargets <~
  [ help(retainSponsors),
    help(increasePhilanthropicDonations),
    help(pledgesBeCollected),
    help(increaseInvolvementSponsorsInPuttingOnEvents),
    help(getCorporateSponsorFunds),
    help(increasedCorporateSponsorFunds),
    help(getPhilanthropicDonations),
    help(acquireGovernmentFunding),
    help(fundsBeRaised) ].
meetCorporateSponsorsNeeds <~
  [ help(exclusiveRelationshipsOfficialPartners2),
    help(corporatePartnerExpectationsBeSharedWithStaff),
    help(quickResponseToSponsors),
    help(recognizeNSponsorContribution1) ].
minimizeCostOfEvents <~
  [ help(increaseInvolvementSponsorsInPuttingOnEvents),
    help(maintain20CostsAgainstRevenuesRatio),
    help(increaseFreeServices) ].
minimizeExpenses <~
  [ help(acquireFreeServices),
    help(attractSponsors2),
    help(marketingFromGovernmentBeAcquired),
    help(sponsorsMarketingChannelsBeUsed),
    help(getFreeAdvertisement),
    hurt(developExternalComunications) ].
positiveAssociationNByConsumers <~
  [ help(cobranding),
    help(recognition),
    help(credibilityCSBrand),
    help(contributeToAGoodCause) ].
positiveImageToEmployees <~
  [ help(engageEmployeesInEvents2),
    help(contributeToAGoodCause) ].
positiveReputation <~ [help(singleCharitableRegistrationNumber1)].
positiveReputationOfCS2 <~
  [ help(useSponsorLogo),
    help(successfulMarketingCampaign),
    help(involvementNotForProfitPartnersInEvents) ].
presentProposalConvincinglyToSponsors <~ [help(presentationSkills)].
proactiveMediaRelationship <~
  [ help(increasedInteractionCounselorsWithMedia),
    help(marketingBeMadeUsingDedicatedCounselor) ].
reachMoreKidsSponsors <~ [help(recognition), help(cobranding)].
recognition <~
  [ help(contributeToAGoodCause),
    help(contributeToACause) ].
recognizeNSponsorContribution2 <~
  [ help(createThankYouAds),
    help(grantExclusiveUseOfBrandAndLogo),
    help(sendRecognitionLetters) ].
reduceInternalCommunicationConfusion <~
  [ help(agreementStaffOverCorporatePartnerExpectations) ].
regionalStaffFeelIncluded <~
  [ help(periodicalCommunicationWithRegionalStaffBeMaintained),
    help(workWithTheRegionsToImplementEvents) ].
retainSponsors <~
  [ help(sponsorRelationshipsBeManaged),
    help(positiveReputation),
    help(increasedAvailabilityCounselorsToPublicSponsors),
    help(increaseNAwareness),
    help(corporatePartnerFundraisingExpectationsBeKnown),
    help(successfulEvents) ].
retainSponsors1 <~
  [ help(trustOfSponsorsTowardsCS2),
    help(companyRelationshipBeRetainedAfterMergers),
    help(upToDateCorporatePartnerInformation),
    help(corporateSponsorsFeelIncluded),
    help(commitmentToCSCauseFromSponsorsEmployees) ].
sponsorshipBeBeneficial <~
  [ help(reachMoreKidsSponsors),
    help(positiveImageToEmployees),
    help(appearAsGoodCorporateCitizens) ].
successfulEvents <~
  [ help(attractSponsors),
    help(timelyProvisionOfFreeServices1),
    help(projectDeadlinesBeMet),
    help(increaseVolunteers),
    help(increaseInvolvementSponsorsInPuttingOnEvents),
    help(uniteVolunteersAndSponsors),
    help(attractEventParticipants),
    help(engagementOfSponsorEmployeesInFundDevelopment),
    help(involveNotForProfitPartnersInEvents),
    help(fundsBeRaised),
    help(happinessStaff3),
    help(goodProjectManagement2) ].
successfulMarketingCampaign <~
  [ help(goodProjectManagement),
    help(happinessStaff1),
    help(experiencedMarketingPartners),
    help(projectDeadlinesBeMet1),
    help(developExternalComunications),
    help(corporatePartnerMarketingExpectationsBeKnown) ].
trustOfDonor <~
  [ help(demonstrableServices2),
    help(credibilityCSBrand2),
    help(receiptBeProvided),
    help(accountabilityOfServices2),
    help(hearCSStories),
    help(responsibleUsageSponsorFunds2),
    help(followHighestEthicalGuidelines2) ].
trustOfSponsorsTowardsCS <~
  [ help(accountabilityOfServices),
    help(followHighestEthicalGuidelines),
    help(credibilityCSBrand),
    help(qualityServices2),
    help(demonstrableServices),
    help(responsibleUsageSponsorFunds) ].
uniteVolunteersAndSponsors <~
  [ help(attractEventParticipants),
    help(increaseInvolvementSponsorsInPuttingOnEvents) ].
upToDateCorporatePartnerInformation <~
  [ make(informationBeSharedWithSponsors) ].
upToDateInformationOnCorporateSponsors <~
  [ help(communicateThroughInternetAndPhone),
    help(biWeeklyConferenceCalls) ].
