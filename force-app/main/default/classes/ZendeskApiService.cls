public without sharing class ZendeskApiService {

    public static void getAllUsers() {
        ZendeskApiHandler.ZendeskAPIResponseWrapper requestResult = ZendeskApiHandler.requestStripeApi(
			'users.json',
			'GET',
			null
		);
        if (requestResult.isError == true) {
            return;
        }
        ZendeskListUserWrapper resultWrapper = (ZendeskListUserWrapper)JSON.deserialize(requestResult.responseBody, ZendeskListUserWrapper.class);
        List<ZendeskUserWrapper> zendeskUsers = new List<ZendeskUserWrapper>();
        zendeskUsers.addAll(resultWrapper?.users);
        Decimal numberOnIterates = resultWrapper?.count/100;
        for (Integer i = 2; i <= numberOnIterates.round(RoundingMode.HALF_UP) + 1; i++) {
            ZendeskApiHandler.ZendeskAPIResponseWrapper nexPageRequestResult = ZendeskApiHandler.requestStripeApi(
                'users.json',
                'GET',
                new Map<String,String>{'page' => String.valueOf(i)}
            );
            ZendeskListUserWrapper nexPageResultWrapper = (ZendeskListUserWrapper)JSON.deserialize(nexPageRequestResult.responseBody, ZendeskListUserWrapper.class);

            if (requestResult.isError == true || nexPageResultWrapper?.users.size() == 0) {
                break;
            }
            zendeskUsers.addAll(nexPageResultWrapper?.users);
        }
        if (zendeskUsers.isEmpty()) {
            return;
        }
        Map<String, ZendeskUserWrapper> searchData = new Map<String, ZendeskUserWrapper>();
        for (ZendeskUserWrapper user : zendeskUsers) {
            if (user?.phone != null && user?.email != null) {
                searchData.put(user?.email, user);
            }
            if (user?.email == null && user?.phone != null) {
                searchData.put(user?.phone, user);
            }
            if (user?.email != null && user?.phone == null) {
                searchData.put(user?.email, user);
            }
        }

        List<Lead> repeatLeads = [
            SELECT
                Name,
                Email,
                Phone
            FROM Lead
            WHERE Email IN :searchData.keySet() OR Phone IN :searchData.keySet()
        ];
        if (!repeatLeads.isEmpty()) {
            for (Lead lead : repeatLeads) {
                if (searchData.get(lead.Email)!= null) {
                    searchData.remove(lead.Email);
                } else if(searchData.get(lead.Phone)!= null) {
                    searchData.remove(lead.Phone);
                }
            }
        }
        List<Contact> repeatContacts = [
            SELECT
                Name,
                Email,
                Phone
            FROM Contact
            WHERE Email IN :searchData.keySet() OR 
                  Phone IN :searchData.keySet()
        ];

        if (!repeatContacts.isEmpty()) {
            for (Contact contact : repeatContacts) {
                if (searchData.get(contact.Email)!= null) {
                    searchData.remove(contact.Email);
                } else if(searchData.get(contact.Phone)!= null) {
                    searchData.remove(contact.Phone);
                }
            }
        }
        List<Account> repeatAccounts = [
            SELECT
                Name,
                PersonEmail,
                Phone,
                PersonMobilePhone
            FROM Account
            WHERE IsPersonAccount = true AND
                  (PersonEmail IN :searchData.keySet() OR
                   Phone IN :searchData.keySet() OR
                   PersonMobilePhone IN :searchData.keySet())
        ];
        if (!repeatAccounts.isEmpty()) {
            for (Account account : repeatAccounts) {
                if (searchData.get(account.PersonEmail)!= null) {
                    searchData.remove(account.PersonEmail);
                } else if(searchData.get(account.Phone)!= null) {
                    searchData.remove(account.Phone);
                } else if(searchData.get(account.PersonMobilePhone)!= null) {
                    searchData.remove(account.PersonMobilePhone);
                }
            }
        }
        if (searchData.isEmpty()) {
            return;
        }
        List<Lead> newLeads = new List<Lead>();
        for (ZendeskUserWrapper user : searchData.values()) {
            newLeads.add(
                new Lead(
                    LastName = user.name,
                    Phone = user.phone,
                    Email = user.email
                )
            );
        }
        if (!newLeads.isEmpty()) {
            insert newLeads;
        }
    }
    private class ZendeskListUserWrapper {
        private List<ZendeskUserWrapper> users;
        private String next_page;
        private Integer count;
    }

    private class ZendeskUserWrapper {
        private String name;
        private String email;
        private String phone;
    }
}