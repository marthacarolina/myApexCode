trigger CampaignTrigger on Campaign (after insert, before delete) {
    new CampaignTriggerHandler().run();
}
