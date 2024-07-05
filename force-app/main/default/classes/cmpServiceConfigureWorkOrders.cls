public without sharing class cmpServiceConfigureWorkOrders {

    @AuraEnabled
    public static AuraResponse getBaseInformationService(String recordId) {
        return new cmpControllerConfigureWorkOrders(recordId).getBaseInformation();
    }

    @AuraEnabled
    public static AuraResponse generateWorkOrdersService(String recordId, String lstOfContractLineItemsJSON) {
        List < ContractLineItem > lstOfContractLineItems = (List < ContractLineItem > ) JSON.deserialize(lstOfContractLineItemsJSON, List < ContractLineItem > .class);
        return new cmpControllerConfigureWorkOrders(recordId, lstOfContractLineItems).generateWorkOrders();
    }

    @AuraEnabled
    public static AuraResponse contractToBeRenewedService(String recordId) {
        return new cmpControllerConfigureWorkOrders(recordId).contractToBeRenewed();
    }
}