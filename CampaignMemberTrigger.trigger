trigger CampaignMemberTrigger on CampaignMember (before delete) {
    new CMemberTriggerHandler().run();
}
