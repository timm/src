% CSSAProgram  (nfr2 dialect: <- rules, <~ contribution lists)
:- discontiguous (<-)/2, (<~)/2, node/2, leaf/1, topgoal/1.
:- dynamic (<-)/2, (<~)/2, node/2, leaf/1, topgoal/1.
node(acquireVolunteerOutreachSkills1,softgoal).
node(experienceForResume,softgoal).
node(speaches,resource).
node(improveImageToKids1,softgoal).
node(speakAtFundraisers,task).
node(acquirePublicSpeakingSkills1,softgoal).
node(attendSAMeetings,task).
leaf(attendSAMeetings).
node(increasedSAResources,softgoal).
node(acquireFundraisingSkills,softgoal).
node(increaseInvolvementOfSAS,softgoal).
node(makeNewFriends1,softgoal).
node(communityServiceHoursCompleted,goal).
topgoal(communityServiceHoursCompleted).
node(increaseSkills,softgoal).
node(trustOfKids,softgoal).
node(sendOutEmails1,task).
node(helpPutOnSATrainingConferences,task).
node(writeArticlesForNewspaper2,task).
node(providePromotionResources,task).
node(acquireFundraisingSkills2,softgoal).
node(createLifeLongVolunteerSpirit,softgoal).
node(saSAreOrganized1,softgoal).
node(expansionOfSAServices,softgoal).
node(runFundraiserInSchools,task).
node(schoolInitiatesPresenation1,task).
leaf(schoolInitiatesPresenation1).
node(createLifeLongVolunteerSpirit1,softgoal).
node(giveCSPresentations1,task).
node(planSocialEvents,task).
leaf(planSocialEvents).
node(getSpeaches,task).
node(runFundraiserInSchools2,task).
node(beConfident,softgoal).
node(getPromotionResources,task).
node(giveCSPresentations,task).
node(increasedSAResources1,softgoal).
leaf(increasedSAResources1).
node(saSAreOutgoing1,softgoal).
node(saSAreOrganized,softgoal).
node(happinessStudentAmbassadors,softgoal).
node(keepInTouchWithVolunteers,softgoal).
node(planAndPutOnReconnectionConferences1,task).
node(retrainSAS,task).
leaf(retrainSAS).
node(findHelpWithPresentations,task).
node(beEnthusiastic,softgoal).
node(haveTimeForSchool2,softgoal).
node(putOnSATrainingConferences,task).
node(improveImageToKids,softgoal).
node(positiveReputationCS,softgoal).
node(haveTimeForSchool1,softgoal).
node(putOnSATrainingConferences1,task).
node(writeArticlesForNewspaper1,task).
node(helpWithPresentations1,task).
node(askForHelpWithPresentations,task).
node(spreadAwareness1,softgoal).
node(sendOutEmails2,task).
node(trustOfKids1,softgoal).
node(acquireVolunteerOutreachSkills,softgoal).
node(planAndPutOnReconnectionConferences2,task).
node(saSAreOutgoing,softgoal).
node(happinessStudentAmbassadors2,softgoal).
node(promotionResources,resource).
node(beOutgoing,softgoal).
node(acquirePublicSpeakingSkills,softgoal).
node(communityServiceHoursCompleted2,goal).
topgoal(communityServiceHoursCompleted2).
node(saSAreConfident1,softgoal).
node(speakAtFundraisers3,task).
node(trainSAS,task).
leaf(trainSAS).
node(permissionForPresentationsBeGiven,goal).
leaf(permissionForPresentationsBeGiven).
topgoal(permissionForPresentationsBeGiven).
node(morePromotionResourcesAvailable,softgoal).
node(saSAreConfident,softgoal).
node(provideSpeaches,task).
leaf(provideSpeaches).
node(haveTimeForSchool,softgoal).
node(giveBackToCommunity2,softgoal).
node(runFundraiserInSchools1,task).
leaf(runFundraiserInSchools1).
node(increaseWritingSkills,softgoal).
node(kidsBeUsedToCommunicateWithOtherKids,goal).
leaf(kidsBeUsedToCommunicateWithOtherKids).
topgoal(kidsBeUsedToCommunicateWithOtherKids).
node(planAndPutOnReconnectionConferences,task).
node(helpPlanAndPutOnReconnectionConferences1,task).
node(increaseWritingSkills1,softgoal).
node(speakAtFundraisers2,task).
node(giveBackToCommunity1,softgoal).
node(increaseWritingSkills2,softgoal).
node(spreadAwareness,softgoal).
node(sendOutEmails,task).
leaf(sendOutEmails).
node(reduceMisconceptions,softgoal).
node(helpPutOnSATrainingConferences1,task).
node(helpWithPresentations,task).
leaf(helpWithPresentations).
node(attendCSMeetings,task).
leaf(attendCSMeetings).
node(beOrganized,softgoal).
node(makeNewFriends,softgoal).
node(qualitySAServices1,softgoal).
node(engagementStudentAmbassadorsInPromotingAwareness,softgoal).
node(acquireFundraisingSkills1,softgoal).
node(saSAreEnthusiastic1,softgoal).
node(promotionResources1,resource).
leaf(promotionResources1).
node(putOnSATrainingConferences2,task).
node(presenationBeInitiated,goal).
topgoal(presenationBeInitiated).
node(initiatePresentationWithSchools,task).
node(qualitySAServices,softgoal).
node(schoolInitiatesPresenation,task).
node(writeArticlesForNewspaper,task).
leaf(writeArticlesForNewspaper).
node(happinessStudentAmbassadors1,softgoal).
node(engageVolunteers,softgoal).
node(giveBackToCommunity,softgoal).
node(acquireVolunteerOutreachSkills2,softgoal).
node(giveCSPresentations2,task).
node(highPresentationAttendance,softgoal).
node(helpPlanAndPutOnReconnectionConferences,task).
node(communityServiceHoursCompleted1,goal).
topgoal(communityServiceHoursCompleted1).
node(acquirePublicSpeakingSkills2,softgoal).
node(positiveReputationCS1,softgoal).
leaf(positiveReputationCS1).
node(findHelpWithPresentations1,task).
node(makeNewFriends2,softgoal).
node(reduceMisconceptions1,softgoal).
node(saSAreEnthusiastic,softgoal).
node(speakAtFundraisers1,task).
node(giveCSPresentations3,task).
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
