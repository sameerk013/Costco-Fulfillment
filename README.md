Things to further enhance this code setup:
    1 Modularize the Terraform Code so that we promote the scalability and Reusability of the code. 
    2. Secrets should NEVER be in the code itself. I would deploy a Azure Key Vault and map the credentials there. 
    3. The state files should be included in github. Have them saves locally or on an azure storage. 