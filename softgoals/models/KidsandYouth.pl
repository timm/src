% Kids and Youth  (nfr2 dialect: <- rules, <~ contribution lists)
:- discontiguous (<-)/2, (<~)/2.
:- dynamic (<-)/2, (<~)/2.
types(goal,
  [helpBeAcquired, servicesBeFree, informationBeAcquiredOnWebsite,
   servicesBeFree1, beInformedOfServiceAnonymity
  ]).
types(softgoal,
  [getEffectiveHelp, safetyOfServiceUsage, highQualityService,
   ownershipOfServiceKids, easyAccessToPostReply, ventEmotions,
   privacy, patientCounselor, confidentialityServices,
   decreasePhoneWaitingTime, confidentialityService,
   childrenDecideWhenToHangUpAndCall, friendlyWebSite1,
   highQualityServices, availabilityService,
   connectBackToTheCommunity1, anonymityService, immediacyService,
   similarityWithOtherKidsProblems, supportAndBeSupportedByOtherKids,
   similarityWithOtherKidsProblems1, ownershipOfServicesKids,
   availabilityServices, decreasePhoneWaitingTime1,
   anonymityServices, effectiveHelpInCrisis,
   effectiveHelpInNonCrisisSituation, connectBackToTheCommunity,
   connectWithOtherKids1, friendlyWebSite, immediacyServices,
   patientCounselor1, easyAccessToPostReply1,
   comfortablenessWithService, connectWithOtherKids
  ]).
types(task,
  [kidsUseAskACounsellorSection, kidsUsePhoneCounselling,
   usePhoneCounselling, implementVoiceCounselling,
   maintainPhoneCounselling, implementVideoCounselling,
   implementEmailCounselling, useVideoCounselling,
   maintainAskACounsellorSection, implementCyberCafPortalChatRoom,
   contactCSAboutNonCrisisSituation, readPollsAboutKids,
   kidsUseGetInformedSectionOfWebSite, implementTextMessaging,
   useTextMessaging, useEmailCounselling,
   kidsUseCyberCafPortalChatRoom,
   maintainGetInformedSectionOfWebSite, useVoiceCounselling,
   kidsUseVoiceCounselling, implementPollsAboutKids,
   implementBulletinBoardWithReplies, kidsReadPollsAboutKids,
   readGeneralQuestionsAndAnswers,
   kidsReadGeneralQuestionsAndAnswers, useCyberCafPortalChatRoom,
   implementGeneralQuestionsAndAnswers, kidsUseTextMessaging,
   implementOneOnOneChatRooms, provideFeedback,
   useAskACounsellorSection, contactCSInCrisis,
   kidsUseBulletinBoardWithReplies, useOneOnOneChatRooms,
   kidsUseOneOnOneChatRooms, informKidsAboutAnonymityOfService,
   feedback, kidsUseVideoCounselling, kidsUseEmailCounselling,
   useBulletinBoardWithReplies, readGetInformedSectionOfWebSite
  ]).
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
