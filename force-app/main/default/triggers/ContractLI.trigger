trigger ContractLI on ServiceContract (after insert) {   
    set<String> QuoteIds = new set<String>();
    List<ServiceContract> upservConList = new List<ServiceContract>();
    List<ContractLineItem> contLineItem = new List<ContractLineItem>();
    for(ServiceContract serConId : trigger.new){
        QuoteIds.add(serConId.Quote__c);
    }
    
    Map<id,Quote> quoteMap = new Map<id,Quote>([Select id,AccountId,ContactId,Account.billingCountry,Account.billingCity,
                                                Account.billingStreet,Account.billingState,Account.billingPostalCode,
                                                Selected_Option__c,ShippingCity,ShippingCountry,
                                                shippingStreet,ShippingState,ShippingPostalCode, (select id,
                                                Frequency__c,QuoteId,PricebookEntryId,Option__c,Quantity,Location__c,
                                                UnitPrice,Product2Id,Other_Location__c FROM QuoteLineItems)
                                                from Quote WHERE id =: QuoteIds AND Selected_Option__c != NUll]);
    
    if(quoteMap.size()>0){
        for(ServiceContract serConId : trigger.new){
            if(quoteMap.containsKey(serConId.Quote__c) == true){
                List<QuoteLineItem>  QLIList= new List<QuoteLineItem>();
                QLIList = quoteMap.get(serConId.Quote__c).QuoteLineItems;
                ServiceContract servcon = new ServiceContract();
                servcon.Id = serConId.Id;
                servcon.AccountId = quoteMap.get(serConId.Quote__c).AccountId;
                servcon.ContactId = quoteMap.get(serConId.Quote__c).ContactId;
                servcon.shippingStreet=quoteMap.get(serConId.Quote__c).shippingStreet;
                servcon.ShippingCity=quoteMap.get(serConId.Quote__c).ShippingCity;
                servcon.ShippingCountry=quoteMap.get(serConId.Quote__c).ShippingCountry;
                servcon.ShippingState=quoteMap.get(serConId.Quote__c).ShippingState;
                servcon.ShippingPostalCode=quoteMap.get(serConId.Quote__c).ShippingPostalCode;
                servcon.billingStreet = quoteMap.get(serConId.Quote__c).Account.billingStreet;
                servcon.billingCity = quoteMap.get(serConId.Quote__c).Account.billingCity;
                servcon.billingCountry = quoteMap.get(serConId.Quote__c).Account.billingCountry;
                servcon.billingState = quoteMap.get(serConId.Quote__c).Account.billingState;
                servcon.billingPostalCode = quoteMap.get(serConId.Quote__c).Account.billingPostalCode;
                upservConList.add(servcon);
                If(QLIList.size()>0){
                    for(QuoteLineItem QLI : QLIList){
                        if(QLI.Option__c ==  quoteMap.get(serConId.Quote__c).Selected_Option__c){
                        ContractLineItem contractline = new ContractLineItem();
                        contractline.ServiceContractId = serConId.Id;
                        contractline.UnitPrice = QLI.UnitPrice;
                        contractline.Quantity = QLI.Quantity;
                        contractline.StartDate = serConId.StartDate;
                        contractline.EndDate = serConId.EndDate;
                        contractline.Frequency__c = QLI.Frequency__c;
                        contractline.Location__c = QLI.Location__c;
                        contractline.PricebookEntryId   = QLI.PricebookEntryId ;
                        contractline.Other_Location__c = QLI.Other_Location__c;
                        contLineItem.add(contractline);
                        }
                        
                        
                    } 
                }
            }else{
                serConId.addError('Quote should have an option');
            }
        }
        if(contLineItem.size()>0){insert contLineItem;}
        if(upservConList.size()>0){update upservConList;}
                
    }
    else{
        for(ServiceContract serConId : trigger.new){
            if(serConId.Adhoc__c == false){
                 serConId.addError('Quote should have an option');
            }
           
        }
        
    }
    
    
}