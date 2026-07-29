% CSSAProgram  (nfr2 dialect: <- rules, <~ contribution lists)
:- discontiguous (<-)/2, (<~)/2.
:- dynamic (<-)/2, (<~)/2.
types(goal,
  [communityServiceHoursCompleted, communityServiceHoursCompleted2,
   permissionForPresentationsBeGiven,
   kidsBeUsedToCommunicateWithOtherKids, presenationBeInitiated,
   communityServiceHoursCompleted1
  ]).
types(softgoal,
  [acquireVolunteerOutreachSkills1, experienceForResume,
   improveImageToKids1, acquirePublicSpeakingSkills1,
   increasedSAResources, acquireFundraisingSkills,
   increaseInvolvementOfSAS, makeNewFriends1, increaseSkills,
   trustOfKids, acquireFundraisingSkills2,
   createLifeLongVolunteerSpirit, saSAreOrganized1,
   expansionOfSAServices, createLifeLongVolunteerSpirit1,
   beConfident, increasedSAResources1, saSAreOutgoing1,
   saSAreOrganized, happinessStudentAmbassadors,
   keepInTouchWithVolunteers, beEnthusiastic, haveTimeForSchool2,
   improveImageToKids, positiveReputationCS, haveTimeForSchool1,
   spreadAwareness1, trustOfKids1, acquireVolunteerOutreachSkills,
   saSAreOutgoing, happinessStudentAmbassadors2, beOutgoing,
   acquirePublicSpeakingSkills, saSAreConfident1,
   morePromotionResourcesAvailable, saSAreConfident,
   haveTimeForSchool, giveBackToCommunity2, increaseWritingSkills,
   increaseWritingSkills1, giveBackToCommunity1,
   increaseWritingSkills2, spreadAwareness, reduceMisconceptions,
   beOrganized, makeNewFriends, qualitySAServices1,
   engagementStudentAmbassadorsInPromotingAwareness,
   acquireFundraisingSkills1, saSAreEnthusiastic1, qualitySAServices,
   happinessStudentAmbassadors1, engageVolunteers,
   giveBackToCommunity, acquireVolunteerOutreachSkills2,
   highPresentationAttendance, acquirePublicSpeakingSkills2,
   positiveReputationCS1, makeNewFriends2, reduceMisconceptions1,
   saSAreEnthusiastic
  ]).
types(task,
  [speaches, speakAtFundraisers, attendSAMeetings, sendOutEmails1,
   helpPutOnSATrainingConferences, writeArticlesForNewspaper2,
   providePromotionResources, runFundraiserInSchools,
   schoolInitiatesPresenation1, giveCSPresentations1,
   planSocialEvents, getSpeaches, runFundraiserInSchools2,
   getPromotionResources, giveCSPresentations,
   planAndPutOnReconnectionConferences1, retrainSAS,
   findHelpWithPresentations, putOnSATrainingConferences,
   putOnSATrainingConferences1, writeArticlesForNewspaper1,
   helpWithPresentations1, askForHelpWithPresentations,
   sendOutEmails2, planAndPutOnReconnectionConferences2,
   promotionResources, speakAtFundraisers3, trainSAS,
   provideSpeaches, runFundraiserInSchools1,
   planAndPutOnReconnectionConferences,
   helpPlanAndPutOnReconnectionConferences1, speakAtFundraisers2,
   sendOutEmails, helpPutOnSATrainingConferences1,
   helpWithPresentations, attendCSMeetings, promotionResources1,
   putOnSATrainingConferences2, initiatePresentationWithSchools,
   schoolInitiatesPresenation, writeArticlesForNewspaper,
   giveCSPresentations2, helpPlanAndPutOnReconnectionConferences,
   findHelpWithPresentations1, speakAtFundraisers1,
   giveCSPresentations3
  ]).
acquireFundraisingSkills <- [acquireFundraisingSkills1].
acquireFundraisingSkills1 <- [acquireFundraisingSkills2].
acquirePublicSpeakingSkills <- [acquirePublicSpeakingSkills1].
acquirePublicSpeakingSkills1 <- [acquirePublicSpeakingSkills2].
acquireVolunteerOutreachSkills <- [acquireVolunteerOutreachSkills1].
acquireVolunteerOutreachSkills1 <- [acquireVolunteerOutreachSkills2].
askForHelpWithPresentations <- [findHelpWithPresentations].
communityServiceHoursCompleted <- [communityServiceHoursCompleted1].
communityServiceHoursCompleted1 <- [writeArticlesForNewspaper].
communityServiceHoursCompleted1 <- [attendCSMeetings].
communityServiceHoursCompleted1 <- [attendSAMeetings].
communityServiceHoursCompleted1 <- [giveCSPresentations1].
communityServiceHoursCompleted1 <- [helpPutOnSATrainingConferences].
communityServiceHoursCompleted1 <- [runFundraiserInSchools1].
communityServiceHoursCompleted1 <-
  [ helpPlanAndPutOnReconnectionConferences ].
communityServiceHoursCompleted1 <- [speakAtFundraisers].
communityServiceHoursCompleted2 <- [communityServiceHoursCompleted].
createLifeLongVolunteerSpirit <- [createLifeLongVolunteerSpirit1].
engagementStudentAmbassadorsInPromotingAwareness <- [spreadAwareness].
findHelpWithPresentations <- [findHelpWithPresentations1].
findHelpWithPresentations1 <- [helpWithPresentations1, sendOutEmails].
getPromotionResources <- [promotionResources].
getSpeaches <- [speaches].
giveBackToCommunity <- [giveBackToCommunity1].
giveBackToCommunity1 <- [giveBackToCommunity2].
giveCSPresentations <- [giveCSPresentations1].
giveCSPresentations1 <- [presenationBeInitiated].
giveCSPresentations1 <- [askForHelpWithPresentations].
giveCSPresentations1 <- [getPromotionResources].
giveCSPresentations2 <- [giveCSPresentations].
giveCSPresentations3 <- [giveCSPresentations2].
happinessStudentAmbassadors <- [happinessStudentAmbassadors1].
happinessStudentAmbassadors1 <- [happinessStudentAmbassadors2].
haveTimeForSchool <- [haveTimeForSchool1].
haveTimeForSchool1 <- [haveTimeForSchool2].
helpPlanAndPutOnReconnectionConferences <- [retrainSAS].
helpPlanAndPutOnReconnectionConferences1 <-
  [ helpPlanAndPutOnReconnectionConferences ].
helpPutOnSATrainingConferences <- [trainSAS].
helpPutOnSATrainingConferences1 <- [helpPutOnSATrainingConferences].
helpWithPresentations1 <- [helpWithPresentations].
improveImageToKids <- [improveImageToKids1].
increaseWritingSkills <- [increaseWritingSkills1].
increaseWritingSkills1 <- [increaseWritingSkills2].
increasedSAResources <- [increasedSAResources1].
initiatePresentationWithSchools <-
  [ permissionForPresentationsBeGiven ].
makeNewFriends <- [makeNewFriends1].
makeNewFriends1 <- [makeNewFriends2].
planAndPutOnReconnectionConferences <-
  [ planAndPutOnReconnectionConferences1 ].
planAndPutOnReconnectionConferences1 <-
  [ planAndPutOnReconnectionConferences2 ].
planAndPutOnReconnectionConferences2 <-
  [ helpPlanAndPutOnReconnectionConferences1 ].
positiveReputationCS <- [positiveReputationCS1].
presenationBeInitiated <- [initiatePresentationWithSchools].
presenationBeInitiated <- [schoolInitiatesPresenation].
promotionResources <- [providePromotionResources].
providePromotionResources <- [promotionResources1].
putOnSATrainingConferences <- [putOnSATrainingConferences1].
putOnSATrainingConferences1 <- [putOnSATrainingConferences2].
putOnSATrainingConferences2 <- [helpPutOnSATrainingConferences1].
qualitySAServices <- [qualitySAServices1].
reduceMisconceptions <- [reduceMisconceptions1].
runFundraiserInSchools <- [runFundraiserInSchools1].
runFundraiserInSchools2 <- [runFundraiserInSchools].
saSAreConfident <- [saSAreConfident1].
saSAreConfident1 <- [beConfident].
saSAreEnthusiastic <- [saSAreEnthusiastic1].
saSAreEnthusiastic1 <- [beEnthusiastic].
saSAreOrganized <- [saSAreOrganized1].
saSAreOrganized1 <- [beOrganized].
saSAreOutgoing <- [saSAreOutgoing1].
saSAreOutgoing1 <- [beOutgoing].
schoolInitiatesPresenation <- [schoolInitiatesPresenation1].
sendOutEmails1 <- [sendOutEmails].
sendOutEmails2 <- [sendOutEmails1].
speaches <- [provideSpeaches].
speakAtFundraisers <- [askForHelpWithPresentations].
speakAtFundraisers1 <- [speakAtFundraisers2].
speakAtFundraisers2 <- [speakAtFundraisers].
speakAtFundraisers3 <- [speakAtFundraisers1].
spreadAwareness1 <- [spreadAwareness].
trustOfKids <- [trustOfKids1].
writeArticlesForNewspaper1 <- [writeArticlesForNewspaper2].
writeArticlesForNewspaper2 <- [writeArticlesForNewspaper].
acquireFundraisingSkills2 <~
  [ help(runFundraiserInSchools1),
    help(attendCSMeetings),
    help(retrainSAS),
    help(trainSAS),
    help(speakAtFundraisers) ].
acquirePublicSpeakingSkills2 <~
  [ help(giveCSPresentations1),
    help(retrainSAS),
    help(speakAtFundraisers),
    help(trainSAS),
    help(runFundraiserInSchools1),
    help(helpPlanAndPutOnReconnectionConferences) ].
acquireVolunteerOutreachSkills2 <~
  [ help(runFundraiserInSchools1),
    help(trainSAS),
    help(retrainSAS),
    help(attendCSMeetings),
    help(helpPlanAndPutOnReconnectionConferences),
    help(giveCSPresentations1) ].
beConfident <~
  [ help(acquireVolunteerOutreachSkills),
    help(acquirePublicSpeakingSkills) ].
beEnthusiastic <~
  [ help(acquireVolunteerOutreachSkills),
    help(acquirePublicSpeakingSkills),
    help(acquireFundraisingSkills) ].
beOrganized <~ [help(acquireFundraisingSkills)].
beOutgoing <~
  [ help(acquireVolunteerOutreachSkills),
    help(acquireFundraisingSkills),
    help(acquirePublicSpeakingSkills) ].
createLifeLongVolunteerSpirit1 <~ [help(engageVolunteers)].
engageVolunteers <~
  [ help(putOnSATrainingConferences),
    help(saSAreEnthusiastic),
    help(morePromotionResourcesAvailable),
    help(happinessStudentAmbassadors),
    help(qualitySAServices1),
    help(positiveReputationCS) ].
expansionOfSAServices <~
  [ help(highPresentationAttendance),
    help(increaseInvolvementOfSAS),
    help(spreadAwareness),
    help(engageVolunteers) ].
experienceForResume <~ [help(increaseSkills)].
giveBackToCommunity2 <~
  [ help(helpWithPresentations),
    help(runFundraiserInSchools1),
    help(speakAtFundraisers),
    help(giveCSPresentations1) ].
happinessStudentAmbassadors2 <~
  [ help(increaseSkills),
    help(makeNewFriends),
    help(experienceForResume),
    help(haveTimeForSchool),
    help(giveBackToCommunity),
    help(communityServiceHoursCompleted2) ].
haveTimeForSchool2 <~ [hurt(communityServiceHoursCompleted1)].
highPresentationAttendance <~ [help(positiveReputationCS)].
improveImageToKids1 <~ [help(kidsBeUsedToCommunicateWithOtherKids)].
increaseInvolvementOfSAS <~
  [ help(keepInTouchWithVolunteers),
    help(planAndPutOnReconnectionConferences),
    help(happinessStudentAmbassadors) ].
increaseSkills <~ [help(beOrganized), help(beConfident)].
increaseWritingSkills2 <~ [help(writeArticlesForNewspaper)].
keepInTouchWithVolunteers <~
  [ help(writeArticlesForNewspaper1),
    help(planAndPutOnReconnectionConferences),
    help(sendOutEmails2) ].
makeNewFriends <~ [help(beOutgoing)].
makeNewFriends2 <~
  [ help(planSocialEvents),
    help(attendSAMeetings),
    help(helpPutOnSATrainingConferences),
    help(writeArticlesForNewspaper),
    help(helpWithPresentations) ].
morePromotionResourcesAvailable <~
  [ help(increasedSAResources1),
    hurt(providePromotionResources) ].
qualitySAServices1 <~
  [ help(happinessStudentAmbassadors),
    help(provideSpeaches),
    help(morePromotionResourcesAvailable),
    help(saSAreConfident),
    help(providePromotionResources),
    help(saSAreOrganized),
    help(kidsBeUsedToCommunicateWithOtherKids) ].
reduceMisconceptions1 <~
  [ help(speakAtFundraisers1),
    help(giveCSPresentations2) ].
saSAreEnthusiastic <~ [help(happinessStudentAmbassadors)].
saSAreOutgoing <~ [help(happinessStudentAmbassadors)].
spreadAwareness <~
  [ help(runFundraiserInSchools2),
    help(writeArticlesForNewspaper1),
    help(morePromotionResourcesAvailable),
    help(speakAtFundraisers1),
    help(giveCSPresentations2) ].
trustOfKids1 <~ [help(kidsBeUsedToCommunicateWithOtherKids)].
