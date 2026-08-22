#!/usr/bin/env python3
# IT System modernization model, reconstructed from SHORT's
# Fig. 2 (Mathew, Menzies, Ernst, Klein; arXiv:1702.05568).
# Structure read from the figure; contribution edges are
# approximate where the diagram's arrows overlap. SHORT's three
# keys: deny the two right-side port leaves (big-bang branch),
# take the j2eeSpecification leaf on the left.
import sys; sys.dont_write_bytecode = True
from run import *

for _n in """modernize incrementalRewrite bigBangRewrite layerSequence
portInternalClients portExternalClients
support existingApps dataService dataModel appFramework monitor
documentation regressionTest chooseDocTool documentationTool
serviceLayer createTestEnv numberTiers twoTier threeTier
svcLayerBizLogicInDb svcLayerExtractedBizLogic
dbVendorTestEnv generalTestEnv bakeoffResult
chooseCandidateSystem dataServiceSpec dataServicePilot
comprehensiveDataModel extensibleDataModel specificDataModel
provideLogicalSchemaInternally defineDataModelSharedData
buildInternalExtensibleModel dataModelPilot
defineExtMandatoryData externalDataModelExtendable
externalClientsGetExactRequest internalClientCoordinates
externalClientCoordinates
j2eeSpecification dotNetFramework customFramework accessControlAssessed accessControlPilot
monitoringPilot
trackFeatureDelivery goodExampleAgileGov
easyShareDataPartners easyShareDataInternally""".split():
  globals()[_n] = Atom(_n)

# a rewrite must actually HAPPEN: each branch derive-then-insist,
# else the or is satisfied by a denied branch and the best world
# is "cancel the project, assume the benefits".
modernize          <= Or([[incrementalRewrite, (incrementalRewrite,'t')],
                          [bigBangRewrite,     (bigBangRewrite,'t')]])

# right side: big bang. No connection to the softgoals (as in
# the paper: "the right-hand-side has no connection to the top
# goals"), and it hurts incremental delivery.
bigBangRewrite     <= layerSequence * hurts(trackFeatureDelivery)
layerSequence      <= portInternalClients * portExternalClients

# left side: incremental rewrite of the six subsystems.
incrementalRewrite <= (support * existingApps * dataService *
                       dataModel * appFramework * monitor *
                       helps(trackFeatureDelivery) *
                       helps(goodExampleAgileGov))
support            <= documentation * regressionTest
documentation      <= chooseDocTool
chooseDocTool      <= documentationTool
regressionTest     <= serviceLayer * createTestEnv * numberTiers
serviceLayer       <= svcLayerBizLogicInDb + svcLayerExtractedBizLogic
numberTiers        <= twoTier + threeTier
createTestEnv      <= dbVendorTestEnv + generalTestEnv + bakeoffResult
existingApps       <= chooseCandidateSystem
dataService        <= dataServiceSpec
dataServiceSpec    <= dataServicePilot
dataModel          <= (comprehensiveDataModel + extensibleDataModel
                       + specificDataModel)
comprehensiveDataModel <= (provideLogicalSchemaInternally *
                           defineDataModelSharedData *
                           buildInternalExtensibleModel *
                           helps(easyShareDataInternally))
buildInternalExtensibleModel <= dataModelPilot
extensibleDataModel <= (defineExtMandatoryData *
                        externalDataModelExtendable *
                        helps(easyShareDataPartners) *
                        helps(easyShareDataInternally))
specificDataModel  <= (externalClientsGetExactRequest +
                       internalClientCoordinates +
                       externalClientCoordinates) * \
                      hurts(easyShareDataPartners)
# framework choice (alternatives approximated -- Fig 2 shows the
# J2EE leaf as ONE option; the others cost extra build leaves):
appFramework       <= j2eeSpecification * helps(goodExampleAgileGov)
appFramework       <= dotNetFramework * customFramework
monitor            <= accessControlAssessed + accessControlPilot \
                      + monitoringPilot

HARD = [modernize]
SOFT = (trackFeatureDelivery + goodExampleAgileGov +
        easyShareDataPartners + easyShareDataInternally)

if __name__ == "__main__": main()
