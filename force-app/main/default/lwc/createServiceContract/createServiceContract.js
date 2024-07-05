import { gql, graphql } from 'lightning/uiGraphQLApi';
import { LightningElement, api, wire } from 'lwc';

export default class CreateServiceContract extends LightningElement {
  @api recordId;

  @wire(graphql, {
    query: gql`
      query AccountInfo($accountId: ID) {
        uiapi {
          query {
            Account(where: { Id: { eq: $accountId } }) {
              edges {
                node {
                  Id
                  Name {
                    value
                  }
                  AccountContactRelations(where: { IsDirect: { eq: true } }) {
                    edges {
                      node {
                        Contact {
                          Name {
                            value
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    `,

    variables: '$variables'
  })
  wireAccounts({ data, error }) {
    if (error) {
      console.error(error);
    } else if (data) {
      console.log(JSON.stringify(data));
    }
  }

  get variables() {
    return {
      accountId: this.recordId
    };
  }
}