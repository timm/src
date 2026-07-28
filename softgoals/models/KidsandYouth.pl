% Kids and Youth  (nfr2 dialect: <- rules, <~ contribution lists)
:- discontiguous (<-)/2, (<~)/2, node/2, leaf/1, topgoal/1.
:- dynamic (<-)/2, (<~)/2, node/2, leaf/1, topgoal/1.
node(kidsUseAskACounsellorSection,task).
node(getEffectiveHelp,softgoal).
node(kidsUsePhoneCounselling,task).
node(helpBeAcquired,goal).
topgoal(helpBeAcquired).
node(usePhoneCounselling,task).
node(servicesBeFree,goal).
topgoal(servicesBeFree).
node(implementVoiceCounselling,task).
leaf(implementVoiceCounselling).
node(maintainPhoneCounselling,task).
leaf(maintainPhoneCounselling).
node(safetyOfServiceUsage,softgoal).
node(implementVideoCounselling,task).
leaf(implementVideoCounselling).
node(implementEmailCounselling,task).
leaf(implementEmailCounselling).
node(highQualityService,softgoal).
node(useVideoCounselling,task).
node(maintainAskACounsellorSection,task).
leaf(maintainAskACounsellorSection).
node(ownershipOfServiceKids,softgoal).
node(easyAccessToPostReply,softgoal).
node(ventEmotions,softgoal).
node(implementCyberCafPortalChatRoom,task).
leaf(implementCyberCafPortalChatRoom).
node(privacy,softgoal).
node(patientCounselor,softgoal).
leaf(patientCounselor).
node(contactCSAboutNonCrisisSituation,task).
leaf(contactCSAboutNonCrisisSituation).
node(confidentialityServices,softgoal).
leaf(confidentialityServices).
node(readPollsAboutKids,task).
node(decreasePhoneWaitingTime,softgoal).
node(confidentialityService,softgoal).
node(kidsUseGetInformedSectionOfWebSite,task).
node(implementTextMessaging,task).
leaf(implementTextMessaging).
node(useTextMessaging,task).
node(useEmailCounselling,task).
node(kidsUseCyberCafPortalChatRoom,task).
node(childrenDecideWhenToHangUpAndCall,softgoal).
node(maintainGetInformedSectionOfWebSite,task).
leaf(maintainGetInformedSectionOfWebSite).
node(useVoiceCounselling,task).
node(friendlyWebSite1,softgoal).
leaf(friendlyWebSite1).
node(highQualityServices,softgoal).
leaf(highQualityServices).
node(availabilityService,softgoal).
node(kidsUseVoiceCounselling,task).
node(connectBackToTheCommunity1,softgoal).
leaf(connectBackToTheCommunity1).
node(anonymityService,softgoal).
node(immediacyService,softgoal).
node(implementPollsAboutKids,task).
leaf(implementPollsAboutKids).
node(similarityWithOtherKidsProblems,softgoal).
leaf(similarityWithOtherKidsProblems).
node(implementBulletinBoardWithReplies,task).
leaf(implementBulletinBoardWithReplies).
node(kidsReadPollsAboutKids,task).
node(supportAndBeSupportedByOtherKids,softgoal).
node(readGeneralQuestionsAndAnswers,task).
node(similarityWithOtherKidsProblems1,softgoal).
node(ownershipOfServicesKids,softgoal).
leaf(ownershipOfServicesKids).
node(availabilityServices,softgoal).
leaf(availabilityServices).
node(decreasePhoneWaitingTime1,softgoal).
leaf(decreasePhoneWaitingTime1).
node(kidsReadGeneralQuestionsAndAnswers,task).
node(useCyberCafPortalChatRoom,task).
node(implementGeneralQuestionsAndAnswers,task).
leaf(implementGeneralQuestionsAndAnswers).
node(informationBeAcquiredOnWebsite,goal).
topgoal(informationBeAcquiredOnWebsite).
node(kidsUseTextMessaging,task).
node(implementOneOnOneChatRooms,task).
leaf(implementOneOnOneChatRooms).
node(provideFeedback,task).
leaf(provideFeedback).
node(useAskACounsellorSection,task).
node(anonymityServices,softgoal).
leaf(anonymityServices).
node(servicesBeFree1,goal).
leaf(servicesBeFree1).
topgoal(servicesBeFree1).
node(contactCSInCrisis,task).
leaf(contactCSInCrisis).
node(effectiveHelpInCrisis,softgoal).
node(effectiveHelpInNonCrisisSituation,softgoal).
node(connectBackToTheCommunity,softgoal).
node(kidsUseBulletinBoardWithReplies,task).
node(useOneOnOneChatRooms,task).
node(connectWithOtherKids1,softgoal).
leaf(connectWithOtherKids1).
node(friendlyWebSite,softgoal).
node(kidsUseOneOnOneChatRooms,task).
node(informKidsAboutAnonymityOfService,task).
node(immediacyServices,softgoal).
leaf(immediacyServices).
node(patientCounselor1,softgoal).
node(feedback,resource).
node(easyAccessToPostReply1,softgoal).
leaf(easyAccessToPostReply1).
node(beInformedOfServiceAnonymity,goal).
leaf(beInformedOfServiceAnonymity).
topgoal(beInformedOfServiceAnonymity).
node(kidsUseVideoCounselling,task).
node(kidsUseEmailCounselling,task).
node(comfortablenessWithService,softgoal).
node(useBulletinBoardWithReplies,task).
node(connectWithOtherKids,softgoal).
node(readGetInformedSectionOfWebSite,task).
anonymityService <- [anonymityServices].
availabilityService <- [availabilityServices].
confidentialityService <- [confidentialityServices].
connectBackToTheCommunity <- [connectBackToTheCommunity1].
connectWithOtherKids <- [connectWithOtherKids1].
decreasePhoneWaitingTime <- [decreasePhoneWaitingTime1].
easyAccessToPostReply <- [easyAccessToPostReply1].
feedback <- [provideFeedback].
friendlyWebSite <- [friendlyWebSite1].
helpBeAcquired <- [useAskACounsellorSection].
helpBeAcquired <- [useCyberCafPortalChatRoom].
helpBeAcquired <- [usePhoneCounselling].
helpBeAcquired <- [useVideoCounselling].
helpBeAcquired <- [useEmailCounselling].
helpBeAcquired <- [useVoiceCounselling].
helpBeAcquired <- [useTextMessaging].
helpBeAcquired <- [useOneOnOneChatRooms].
highQualityService <- [highQualityServices].
immediacyService <- [immediacyServices].
informKidsAboutAnonymityOfService <- [beInformedOfServiceAnonymity].
informationBeAcquiredOnWebsite <- [readPollsAboutKids].
informationBeAcquiredOnWebsite <- [readGeneralQuestionsAndAnswers].
informationBeAcquiredOnWebsite <- [readGetInformedSectionOfWebSite].
kidsReadGeneralQuestionsAndAnswers <-
  [ readGeneralQuestionsAndAnswers ].
kidsReadPollsAboutKids <- [readPollsAboutKids].
kidsUseAskACounsellorSection <- [useAskACounsellorSection].
kidsUseBulletinBoardWithReplies <- [useBulletinBoardWithReplies].
kidsUseCyberCafPortalChatRoom <- [useCyberCafPortalChatRoom].
kidsUseEmailCounselling <- [useEmailCounselling].
kidsUseGetInformedSectionOfWebSite <-
  [ readGetInformedSectionOfWebSite ].
kidsUseOneOnOneChatRooms <- [useOneOnOneChatRooms].
kidsUsePhoneCounselling <- [usePhoneCounselling].
kidsUseTextMessaging <- [useTextMessaging].
kidsUseVideoCounselling <- [useVideoCounselling].
kidsUseVoiceCounselling <- [useVoiceCounselling].
ownershipOfServiceKids <- [ownershipOfServicesKids].
patientCounselor1 <- [patientCounselor].
readGeneralQuestionsAndAnswers <-
  [ implementGeneralQuestionsAndAnswers ].
readGetInformedSectionOfWebSite <-
  [ maintainGetInformedSectionOfWebSite ].
readPollsAboutKids <- [implementPollsAboutKids].
servicesBeFree <- [servicesBeFree1].
similarityWithOtherKidsProblems1 <- [similarityWithOtherKidsProblems].
useAskACounsellorSection <- [maintainAskACounsellorSection].
useBulletinBoardWithReplies <- [implementBulletinBoardWithReplies].
useCyberCafPortalChatRoom <- [implementCyberCafPortalChatRoom].
useEmailCounselling <- [implementEmailCounselling].
useOneOnOneChatRooms <- [implementOneOnOneChatRooms].
usePhoneCounselling <- [maintainPhoneCounselling].
useTextMessaging <- [implementTextMessaging].
useVideoCounselling <- [implementVideoCounselling].
useVoiceCounselling <- [implementVoiceCounselling].
childrenDecideWhenToHangUpAndCall <~ [make(ownershipOfServiceKids)].
comfortablenessWithService <~
  [ help(ownershipOfServiceKids),
    help(supportAndBeSupportedByOtherKids),
    help(servicesBeFree1),
    help(anonymityService),
    help(similarityWithOtherKidsProblems1),
    help(beInformedOfServiceAnonymity),
    hurt(provideFeedback),
    help(confidentialityService),
    help(patientCounselor1) ].
effectiveHelpInCrisis <~
  [ help(decreasePhoneWaitingTime),
    help(immediacyService) ].
effectiveHelpInNonCrisisSituation <~ [help(immediacyService)].
getEffectiveHelp <~
  [ help(patientCounselor1),
    help(effectiveHelpInCrisis),
    help(highQualityService),
    help(availabilityService),
    help(easyAccessToPostReply),
    help(friendlyWebSite),
    help(ventEmotions),
    help(effectiveHelpInNonCrisisSituation) ].
privacy <~
  [ hurt(provideFeedback),
    help(childrenDecideWhenToHangUpAndCall),
    help(confidentialityService),
    help(anonymityService) ].
safetyOfServiceUsage <~
  [ help(confidentialityService),
    help(anonymityService),
    help(immediacyService) ].
supportAndBeSupportedByOtherKids <~ [help(connectWithOtherKids)].
ventEmotions <~ [help(patientCounselor1)].
