% CSCounsellingManagement  (nfr2 dialect: <- rules, <~ contribution lists)
:- discontiguous (<-)/2, (<~)/2.
:- dynamic (<-)/2, (<~)/2.
types(goal,
  [anITTrainerBePresent, professionalCounsellorsBeUsed1,
   callsBeRecordedIntoADataBase1, professionalCounsellorsBeUsed,
   contractsBeReviewed,
   performanceReviewInformationBeCollectedInDataBase,
   anITTrainerBePresent1, bilingualCounsellorsBeHired1,
   counsellorsPassProbationWithinSixMonths,
   staffPerformanceBeManaged, callsBeMonitored,
   performanceReviewInformationBeCollectedInDataBase1,
   supervisionBePerformedAtLeastEvery3Months1,
   aTrainingRoomBePresent, policiesBeReviewed,
   bilingualCounsellorsBeHired, aTrainingComputerBePresent1,
   counsellingPoliciesBeFollowed, feedbackToCounsellorsBeProvided,
   counsellorsBeKeptInformed, bilingualCounsellorsBeHired2,
   analyzeStaffingLevels, analyzeServiceLevels,
   feedbackToCounsellorsBeProvided2,
   holesInOperationsManagingBeRemoved,
   fullTimeNightComplementBeAcquired, callsBeRecordedIntoADataBase,
   feedbackToCounsellorsBeProvided1,
   supervisionBePerformedAtLeastEvery3Months2,
   aTrainingProgramBePresent,
   supervisionBePerformedAtLeastEvery3Months,
   technologyBeUsedToEnsureCounsellorsAreKeepingCorrectHours,
   aTrainingComputerBePresent,
   threeMonthsOfReviewBeGivenToNewCounsellors,
   employeeLearningAndTrainingBeManaged,
   counsellingPoliciesBeFollowed1
  ]).
types(softgoal,
  [considerationOfFeedbackManagers, highQualityCounselling1,
   accommodateSchedulesCounsellingManagers1,
   reduceTurnoverCounsellors,
   performCounsellingAsInstructedBySupervisorCounsellors1,
   increaseComfortablenessWithLearningProcess,
   improveQualityAssuranceTechnology,
   accommodateSchedulesCounsellors, reduceCostOfCounsellingHR1,
   improveITSkillsOfCounsellors2,
   effectiveUseOfTechnologyCounsellors2,
   improvedQualityAssuranceCounsellingReviewsAndEvaluation,
   improveHiringProcessOfCounsellors,
   increaseITTrainingForCounsellors1,
   clearCommunicationAboutThePurposeOfITToCounselors,
   pressureCounsellorsToProvideOnlineServices2,
   accommodateSchedulesCounsellingManagers2,
   improveCallRecordingEquipment1, improveTrainingForCounsellors,
   improveJobDescriptionsCounsellors, positiveInternalOpinion,
   improveHiringProcessOfCounsellors2, rigorousEmployeeEvaluations,
   happinessCounsellors1, improvedWritingSkillsCounsellors,
   performCounsellingAsInstructedBySupervisorCounsellors,
   improveITSkillsOfCounsellors1, accountabilityServices,
   increasedCounsellingResources, helpAsManyKidsAsPossible,
   facilitateFasterChangesInCounsellorDuties,
   reduceCostOfCounsellingHR2, reduceTurnoverCounsellingManagement,
   considerCounsellorsFeedback, accurateCallerStatistics,
   improvedWritingSkillsCounsellors3, avoidLiabilityProblems1,
   increasedUnderstandingOfPurposesOfITCounsellors,
   environmentConductiveToConcentration,
   improveHiringProcessOfCounsellors1,
   supportDayToDayOnTheFloorNeedsOfCounsellors,
   happinessCounsellingManager, improveITSkills,
   professionalWorkEnvironment, increaseFundingForTraining,
   accommodateSchedulesCounsellingManagers,
   supportAnalysisCounsellorsTime1, highQualityOnlineCounselling,
   continualImprovementCounsellingSkills2,
   increaseITMethodsToAcquireFeedback, highQualityCounselling2,
   improvedWritingSkillsCounsellors2,
   sufficientCounsellingResources1, avoidLiabilityProblems,
   callDurationConsistencyCounsellors, increaseFundingForTraining1,
   counsellingTrainingManagement,
   clearerCallClassificationCatagories1,
   effectiveUseOfTechnologyCounsellors1,
   increasedEmphasisOnITInHiringProcessOfCounsellors,
   avoidRefusalOfServices, increaseEnthusiasmCounsellorsForIT,
   pressureCounsellorsToProvideOnlineServices,
   improvedQualityAssuranceCounsellingReviewsAndEvaluation2,
   happinessCounsellingManager1, reduceStaggeringOfSchedules1,
   effectiveScheduling2, increaseNumberOfCounsellors1, salary,
   increasedCounsellingResource,
   avoidRelationshipsWithSpecificCounsellor,
   helpAsManyKidsAsPossible1, sufficientCounsellingResources,
   supportDayToDayClinicalNeedsOfCounsellors2,
   increasedEmphasisOnITInHiringProcessOfCounsellors1,
   increaseCounsellorsExperienceWithTechnology,
   reduceResistanceCounsellorsForIT,
   advanceNoticeToCounsellorsAboutITTransitions,
   highQualityCounselling, effectiveScheduling,
   effectiveUseOfTechnologyCounsellors,
   increasedEmphasisOnITInHiringProcessOfCounsellors2,
   increaseCommunicationBetweenCounsellorsAndSupervisors,
   reduceCostOfCounsellingHR, reduceSpendingOnEmployeesSalaries,
   positiveInternalOpinion1, continualImprovementCounsellingSkills1,
   supportCounsellors, professionalWorkEnvironment1,
   happinessCounsellingManagement, counsellingManager,
   avoidRelationshipsWithSpecificCounsellor1,
   facilitateFasterChangesInCounsellorDuties1,
   accountabilityServices1,
   supportDayToDayClinicalNeedsOfCounsellors,
   improveCallRecordingEquipment, reduceStaggeringOfSchedules,
   accommodateSchedulesCounsellors1,
   continualImprovementCounsellingSkills,
   positiveAttitudeTowardsITCounsellors, effectiveScheduling1,
   happinessOfCounsellors, accommodateSchedulesCounsellors2,
   improvedQualityAssuranceCounsellingReviewsAndEvaluation1,
   increaseITTrainingForCounsellors, improveITSkillsOfCounsellors,
   increaseTrainingForCounsellors, supportAnalysisCounsellorsTime,
   happinessCounsellors, clearerCallClassificationCatagories,
   provideOnlineServicesAllCounsellors,
   supportDayToDayClinicalNeedsOfCounsellors1,
   sufficientCounsellingResources2, qualifiedCounsellors,
   pressureCounsellorsToProvideOnlineServices1, increaseFeedback,
   increaseNumberOfCounsellors2, improvedWritingSkillsCounsellors1,
   increaseITMethodsToAcquireFeedback1, easierJob,
   increaseNumberOfCounsellors
  ]).
types(task,
  [trainingBeGivenToNewEmployees, secondReadingOfWebPosts,
   analyzeCallStatistics1, communicateCSInformationToCounsellors,
   manageCounsellors, listenToLiveCall, debriefWithCounsellors,
   acquireWebTrainingFromOperations, debriefWebPosts, doubleHeadSet,
   provideOneOnOneSupportToCounsellors, analyzeCallStatistics,
   putOnWebModeratorMeetings, putOnCounsellingWorkshops,
   negotiateWithCounsellorsUnion, counsellingResources,
   attendPartTimeMeetings, trackCallVolume,
   createCallClassificationCatagories, analyzeCallStatistics2,
   counsellingWorkshops, secondReadingOfWebPosts1,
   provideFeedbackOnWebPosts, performCounsellingQualityAssurance,
   trainingBeGivenToCurrentEmployees, acquireResourcesForStaffing,
   negotiateWithCounsellorsUnion1, trackCallLengths,
   webModeratorMeetings, hireCounsellingManagers, hireCounsellors,
   performSupervision, counsellingPolicies,
   negotiateWithCounsellorsUnion2, debriefCalls,
   secondReadingOfWebPosts2, reviewTape, setCounsellingPolicies,
   requestShifts, writeYearlyPeformanceEvaluationsForCounsellors,
   historicalDataOfCallVolumes, manageStaffingAndRecruiting,
   putOnOrientationProcessForCousellors, callStatistics,
   performSupervisionForExperiencedCounsellors, counsellorsBePaid,
   performSupervisionForNewCounsellors, makeSchedules, useBluePumpkin
  ]).
aTrainingComputerBePresent <- [aTrainingComputerBePresent1].
accommodateSchedulesCounsellingManagers1 <-
  [ accommodateSchedulesCounsellingManagers ].
accommodateSchedulesCounsellingManagers2 <-
  [ accommodateSchedulesCounsellingManagers1 ].
accommodateSchedulesCounsellors <- [accommodateSchedulesCounsellors2].
accommodateSchedulesCounsellors2 <-
  [ accommodateSchedulesCounsellors1 ].
accountabilityServices <- [accountabilityServices1].
acquireResourcesForStaffing <- [counsellingResources].
anITTrainerBePresent <- [anITTrainerBePresent1].
analyzeCallStatistics <-
  [ historicalDataOfCallVolumes,
    callStatistics,
    trackCallLengths ].
analyzeCallStatistics <-
  [ historicalDataOfCallVolumes,
    callStatistics,
    trackCallVolume ].
analyzeCallStatistics1 <- [analyzeCallStatistics].
analyzeCallStatistics2 <- [analyzeCallStatistics1].
avoidLiabilityProblems <- [avoidLiabilityProblems1].
avoidRelationshipsWithSpecificCounsellor1 <-
  [ avoidRelationshipsWithSpecificCounsellor ].
bilingualCounsellorsBeHired1 <- [bilingualCounsellorsBeHired].
bilingualCounsellorsBeHired2 <- [bilingualCounsellorsBeHired1].
callsBeMonitored <- [listenToLiveCall].
callsBeMonitored <- [reviewTape].
callsBeRecordedIntoADataBase <- [callsBeRecordedIntoADataBase1].
clearerCallClassificationCatagories1 <-
  [ clearerCallClassificationCatagories ].
considerationOfFeedbackManagers <- [considerCounsellorsFeedback].
continualImprovementCounsellingSkills1 <-
  [ continualImprovementCounsellingSkills2 ].
continualImprovementCounsellingSkills2 <-
  [ continualImprovementCounsellingSkills ].
counsellingPolicies <- [setCounsellingPolicies].
counsellingPoliciesBeFollowed1 <- [counsellingPoliciesBeFollowed].
counsellingWorkshops <- [putOnCounsellingWorkshops].
counsellorsBeKeptInformed <- [communicateCSInformationToCounsellors].
debriefWithCounsellors <- [debriefWebPosts].
debriefWithCounsellors <- [debriefCalls].
effectiveScheduling1 <- [effectiveScheduling2].
effectiveScheduling2 <- [effectiveScheduling].
effectiveUseOfTechnologyCounsellors1 <-
  [ effectiveUseOfTechnologyCounsellors2 ].
effectiveUseOfTechnologyCounsellors2 <-
  [ effectiveUseOfTechnologyCounsellors ].
employeeLearningAndTrainingBeManaged <-
  [ trainingBeGivenToCurrentEmployees ].
employeeLearningAndTrainingBeManaged <-
  [ trainingBeGivenToNewEmployees ].
facilitateFasterChangesInCounsellorDuties <-
  [ facilitateFasterChangesInCounsellorDuties1 ].
feedbackToCounsellorsBeProvided1 <-
  [ feedbackToCounsellorsBeProvided2 ].
feedbackToCounsellorsBeProvided2 <- [feedbackToCounsellorsBeProvided].
happinessCounsellingManagement <- [happinessCounsellingManager].
happinessCounsellingManager1 <- [happinessCounsellingManagement].
happinessCounsellors <- [happinessCounsellors1].
happinessOfCounsellors <- [happinessCounsellors1].
helpAsManyKidsAsPossible1 <- [helpAsManyKidsAsPossible].
highQualityCounselling <- [highQualityCounselling2].
highQualityCounselling1 <- [highQualityCounselling].
improveCallRecordingEquipment1 <- [improveCallRecordingEquipment].
improveHiringProcessOfCounsellors1 <-
  [ improveHiringProcessOfCounsellors2 ].
improveHiringProcessOfCounsellors2 <-
  [ improveHiringProcessOfCounsellors ].
improveITSkillsOfCounsellors <- [improveITSkills].
improveITSkillsOfCounsellors1 <- [improveITSkillsOfCounsellors2].
improveITSkillsOfCounsellors2 <- [improveITSkillsOfCounsellors].
improvedQualityAssuranceCounsellingReviewsAndEvaluation <-
  [ improvedQualityAssuranceCounsellingReviewsAndEvaluation2 ].
improvedQualityAssuranceCounsellingReviewsAndEvaluation2 <-
  [ improvedQualityAssuranceCounsellingReviewsAndEvaluation1 ].
improvedWritingSkillsCounsellors1 <-
  [ improvedWritingSkillsCounsellors ].
improvedWritingSkillsCounsellors2 <-
  [ improvedWritingSkillsCounsellors3 ].
improvedWritingSkillsCounsellors3 <-
  [ improvedWritingSkillsCounsellors1 ].
increaseFundingForTraining1 <- [increaseFundingForTraining].
increaseITMethodsToAcquireFeedback1 <-
  [ increaseITMethodsToAcquireFeedback ].
increaseITTrainingForCounsellors1 <-
  [ increaseITTrainingForCounsellors ].
increaseNumberOfCounsellors <- [increaseNumberOfCounsellors1].
increaseNumberOfCounsellors1 <- [increaseNumberOfCounsellors2].
increasedCounsellingResource <- [increasedCounsellingResources].
increasedEmphasisOnITInHiringProcessOfCounsellors <-
  [ increasedEmphasisOnITInHiringProcessOfCounsellors2 ].
increasedEmphasisOnITInHiringProcessOfCounsellors1 <-
  [ increasedEmphasisOnITInHiringProcessOfCounsellors ].
listenToLiveCall <- [doubleHeadSet].
makeSchedules <- [analyzeServiceLevels].
makeSchedules <- [holesInOperationsManagingBeRemoved].
makeSchedules <- [analyzeCallStatistics].
makeSchedules <- [analyzeStaffingLevels].
manageCounsellors <- [negotiateWithCounsellorsUnion].
manageCounsellors <- [setCounsellingPolicies].
manageCounsellors <- [counsellingPoliciesBeFollowed1].
manageCounsellors <-
  [ technologyBeUsedToEnsureCounsellorsAreKeepingCorrectHours ].
manageCounsellors <- [counsellorsBeKeptInformed].
manageCounsellors <- [createCallClassificationCatagories].
manageStaffingAndRecruiting <- [counsellorsBePaid].
manageStaffingAndRecruiting <- [hireCounsellingManagers].
manageStaffingAndRecruiting <- [hireCounsellors].
manageStaffingAndRecruiting <- [contractsBeReviewed].
manageStaffingAndRecruiting <- [acquireResourcesForStaffing].
manageStaffingAndRecruiting <- [fullTimeNightComplementBeAcquired].
manageStaffingAndRecruiting <- [policiesBeReviewed].
negotiateWithCounsellorsUnion1 <- [negotiateWithCounsellorsUnion].
negotiateWithCounsellorsUnion2 <- [negotiateWithCounsellorsUnion1].
performCounsellingAsInstructedBySupervisorCounsellors1 <-
  [ performCounsellingAsInstructedBySupervisorCounsellors ].
performCounsellingQualityAssurance <-
  [ performSupervisionForNewCounsellors ].
performSupervision <- [performSupervisionForNewCounsellors].
performSupervision <- [performSupervisionForExperiencedCounsellors].
performSupervisionForExperiencedCounsellors <-
  [ supervisionBePerformedAtLeastEvery3Months ].
performSupervisionForExperiencedCounsellors <-
  [ writeYearlyPeformanceEvaluationsForCounsellors ].
performSupervisionForExperiencedCounsellors <-
  [ performCounsellingQualityAssurance ].
performSupervisionForExperiencedCounsellors <-
  [ provideFeedbackOnWebPosts ].
performSupervisionForExperiencedCounsellors <- [callsBeMonitored].
performSupervisionForNewCounsellors <-
  [ threeMonthsOfReviewBeGivenToNewCounsellors ].
performSupervisionForNewCounsellors <-
  [ feedbackToCounsellorsBeProvided ].
performSupervisionForNewCounsellors <-
  [ counsellorsPassProbationWithinSixMonths ].
performanceReviewInformationBeCollectedInDataBase <-
  [ performanceReviewInformationBeCollectedInDataBase1 ].
positiveInternalOpinion1 <- [positiveInternalOpinion].
pressureCounsellorsToProvideOnlineServices1 <-
  [ pressureCounsellorsToProvideOnlineServices2 ].
pressureCounsellorsToProvideOnlineServices2 <-
  [ pressureCounsellorsToProvideOnlineServices ].
professionalCounsellorsBeUsed1 <- [professionalCounsellorsBeUsed].
professionalWorkEnvironment <- [professionalWorkEnvironment1].
provideFeedbackOnWebPosts <- [secondReadingOfWebPosts].
reduceCostOfCounsellingHR1 <-
  [ reduceCostOfCounsellingHR,
    reduceCostOfCounsellingHR2 ].
reduceStaggeringOfSchedules <- [reduceStaggeringOfSchedules1].
salary <- [counsellorsBePaid].
secondReadingOfWebPosts <- [acquireWebTrainingFromOperations].
secondReadingOfWebPosts1 <- [secondReadingOfWebPosts2].
secondReadingOfWebPosts2 <- [secondReadingOfWebPosts].
staffPerformanceBeManaged <- [performSupervision].
sufficientCounsellingResources <-
  [ sufficientCounsellingResources2,
    sufficientCounsellingResources1 ].
supervisionBePerformedAtLeastEvery3Months1 <-
  [ supervisionBePerformedAtLeastEvery3Months2 ].
supervisionBePerformedAtLeastEvery3Months2 <-
  [ supervisionBePerformedAtLeastEvery3Months ].
supportAnalysisCounsellorsTime <- [supportAnalysisCounsellorsTime1].
supportDayToDayClinicalNeedsOfCounsellors <-
  [ supportDayToDayClinicalNeedsOfCounsellors1 ].
supportDayToDayClinicalNeedsOfCounsellors2 <-
  [ supportDayToDayClinicalNeedsOfCounsellors ].
trackCallLengths <- [useBluePumpkin].
trackCallVolume <- [useBluePumpkin].
trainingBeGivenToCurrentEmployees <-
  [ putOnOrientationProcessForCousellors ].
trainingBeGivenToCurrentEmployees <- [putOnCounsellingWorkshops].
trainingBeGivenToNewEmployees <-
  [ putOnOrientationProcessForCousellors ].
webModeratorMeetings <- [putOnWebModeratorMeetings].
accommodateSchedulesCounsellingManagers <~
  [ hurt(effectiveScheduling) ].
accommodateSchedulesCounsellingManagers2 <~ [help(requestShifts)].
accommodateSchedulesCounsellors1 <~ [hurt(effectiveScheduling)].
accountabilityServices1 <~ [help(accurateCallerStatistics)].
accurateCallerStatistics <~
  [ help(clearerCallClassificationCatagories1) ].
advanceNoticeToCounsellorsAboutITTransitions <~
  [ hurt(facilitateFasterChangesInCounsellorDuties) ].
avoidLiabilityProblems <~ [help(secondReadingOfWebPosts1)].
avoidRefusalOfServices <~
  [ help(avoidRelationshipsWithSpecificCounsellor1) ].
callDurationConsistencyCounsellors <~ [help(analyzeCallStatistics2)].
continualImprovementCounsellingSkills <~
  [ help(increaseTrainingForCounsellors),
    help(improveTrainingForCounsellors),
    help(feedbackToCounsellorsBeProvided1),
    help(increaseFeedback),
    help(improveITSkillsOfCounsellors),
    help(supervisionBePerformedAtLeastEvery3Months1),
    help(professionalCounsellorsBeUsed),
    help(increaseComfortablenessWithLearningProcess) ].
easierJob <~ [hurt(negotiateWithCounsellorsUnion2)].
effectiveScheduling <~ [make(makeSchedules)].
effectiveUseOfTechnologyCounsellors <~
  [ help(positiveAttitudeTowardsITCounsellors),
    help(improveITSkillsOfCounsellors1) ].
environmentConductiveToConcentration <~
  [ help(professionalWorkEnvironment) ].
happinessCounsellingManager <~
  [ help(environmentConductiveToConcentration),
    help(accommodateSchedulesCounsellingManagers2),
    help(easierJob),
    help(avoidLiabilityProblems) ].
happinessCounsellingManager1 <~
  [ help(reduceTurnoverCounsellors),
    help(reduceTurnoverCounsellingManagement) ].
happinessCounsellors <~
  [ help(reduceTurnoverCounsellors),
    help(reduceTurnoverCounsellingManagement),
    hurt(reduceSpendingOnEmployeesSalaries),
    help(increasedCounsellingResource),
    help(positiveInternalOpinion1) ].
happinessOfCounsellors <~
  [ help(considerCounsellorsFeedback),
    help(increaseCommunicationBetweenCounsellorsAndSupervisors),
    hurt(callDurationConsistencyCounsellors),
    help(supportCounsellors),
    help(increaseNumberOfCounsellors),
    hurt(pressureCounsellorsToProvideOnlineServices1),
    help(clearerCallClassificationCatagories1),
    help(accommodateSchedulesCounsellors) ].
helpAsManyKidsAsPossible <~
  [ help(avoidRefusalOfServices),
    help(bilingualCounsellorsBeHired2),
    help(effectiveScheduling1) ].
highQualityCounselling <~
  [ help(continualImprovementCounsellingSkills1),
    help(improvedQualityAssuranceCounsellingReviewsAndEvaluation),
    help(callDurationConsistencyCounsellors),
    help(supportCounsellors),
    help(happinessOfCounsellors),
    help(qualifiedCounsellors),
    help(effectiveUseOfTechnologyCounsellors1),
    help(performCounsellingAsInstructedBySupervisorCounsellors1),
    help(highQualityOnlineCounselling) ].
highQualityOnlineCounselling <~
  [ help(effectiveUseOfTechnologyCounsellors1),
    help(improvedWritingSkillsCounsellors2) ].
improveHiringProcessOfCounsellors <~
  [ help(improveJobDescriptionsCounsellors),
    help(increasedEmphasisOnITInHiringProcessOfCounsellors2) ].
improveITSkillsOfCounsellors <~
  [ help(increaseCounsellorsExperienceWithTechnology),
    help(increasedEmphasisOnITInHiringProcessOfCounsellors1),
    help(increaseITTrainingForCounsellors1) ].
improveITSkillsOfCounsellors1 <~ [help(putOnWebModeratorMeetings)].
improveQualityAssuranceTechnology <~
  [ help(performanceReviewInformationBeCollectedInDataBase),
    help(callsBeRecordedIntoADataBase),
    help(improveCallRecordingEquipment1) ].
improveTrainingForCounsellors <~
  [ help(aTrainingRoomBePresent),
    help(aTrainingProgramBePresent) ].
improvedQualityAssuranceCounsellingReviewsAndEvaluation1 <~
  [ help(improveQualityAssuranceTechnology),
    help(rigorousEmployeeEvaluations) ].
increaseCommunicationBetweenCounsellorsAndSupervisors <~
  [ help(considerCounsellorsFeedback),
    help(counsellorsBeKeptInformed),
    help(debriefWithCounsellors),
    help(attendPartTimeMeetings) ].
increaseEnthusiasmCounsellorsForIT <~
  [ help(increasedUnderstandingOfPurposesOfITCounsellors),
    hurt(supportAnalysisCounsellorsTime) ].
increaseFeedback <~ [help(increaseITMethodsToAcquireFeedback1)].
increaseITTrainingForCounsellors1 <~
  [ help(anITTrainerBePresent),
    help(aTrainingComputerBePresent) ].
increaseNumberOfCounsellors2 <~ [help(increasedCounsellingResource)].
increaseTrainingForCounsellors <~
  [ help(increaseFundingForTraining1),
    help(aTrainingProgramBePresent),
    help(increaseITTrainingForCounsellors1),
    help(aTrainingRoomBePresent) ].
increasedCounsellingResource <~ [help(reduceCostOfCounsellingHR2)].
increasedUnderstandingOfPurposesOfITCounsellors <~
  [ help(clearCommunicationAboutThePurposeOfITToCounselors) ].
positiveAttitudeTowardsITCounsellors <~
  [ help(increaseEnthusiasmCounsellorsForIT),
    help(reduceResistanceCounsellorsForIT) ].
provideOnlineServicesAllCounsellors <~
  [ help(pressureCounsellorsToProvideOnlineServices),
    help(positiveAttitudeTowardsITCounsellors),
    help(improveITSkillsOfCounsellors1),
    help(facilitateFasterChangesInCounsellorDuties) ].
qualifiedCounsellors <~
  [ help(improvedQualityAssuranceCounsellingReviewsAndEvaluation),
    help(improveHiringProcessOfCounsellors1) ].
reduceCostOfCounsellingHR <~ [help(analyzeCallStatistics)].
reduceCostOfCounsellingHR2 <~
  [ hurt(increaseNumberOfCounsellors2),
    hurt(bilingualCounsellorsBeHired),
    help(reduceSpendingOnEmployeesSalaries) ].
reduceResistanceCounsellorsForIT <~
  [ help(advanceNoticeToCounsellorsAboutITTransitions),
    help(increasedUnderstandingOfPurposesOfITCounsellors),
    hurt(supportAnalysisCounsellorsTime) ].
reduceStaggeringOfSchedules1 <~ [hurt(effectiveScheduling)].
reduceTurnoverCounsellingManagement <~
  [ help(happinessCounsellingManager1) ].
reduceTurnoverCounsellors <~ [help(happinessCounsellors)].
sufficientCounsellingResources1 <~
  [ help(increasedCounsellingResource) ].
sufficientCounsellingResources2 <~ [help(effectiveScheduling)].
supportCounsellors <~
  [ help(provideOneOnOneSupportToCounsellors),
    help(supportDayToDayOnTheFloorNeedsOfCounsellors),
    help(supportDayToDayClinicalNeedsOfCounsellors2),
    help(debriefWithCounsellors) ].
supportDayToDayClinicalNeedsOfCounsellors1 <~
  [ help(improveQualityAssuranceTechnology),
    help(feedbackToCounsellorsBeProvided),
    help(provideFeedbackOnWebPosts) ].
