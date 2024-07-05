/*
    @description Common Response Structure for Lightning Components.
*/
public class AuraResponse {

    /* Public Class Members */

    // getter setter for isSuccess
    @AuraEnabled
    public Boolean isSuccess {
        get;
        set;
    }

    // getter setter for message
    @AuraEnabled
    public String message {
        get;
        set;
    }

    // getter setter for response
    @AuraEnabled
    public String response {
        get;
        set;
    }

    /* Constructors */
    public AuraResponse(Boolean isSuccess, String message, String response) {
        this.isSuccess = isSuccess;
        this.response = response;
        this.message = message;
    }
}