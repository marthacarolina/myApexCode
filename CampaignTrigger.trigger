trigger CampaignTrigger on Campaign (after insert, after update, before delete) {
    new CampaignTriggerHandler().run();
}
