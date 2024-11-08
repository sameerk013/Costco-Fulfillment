#Things to further enhance this code setup:

To-DO List:



    1 Modularize the Terraform Code so that we promote the scalability and Reusability of the code. 
    2. Secrets should NEVER be in the code itself. Deploy an Azure Key Vault and map the credentials there. 
    3. The state files should be included in github. Save it locally or on an azure storage. 
    4. Include DNS for the hosts as you should not be connecting via the IP Addresses. 
    5. Seperate state files so that we would override or corrupt resources that dont need to be included#
