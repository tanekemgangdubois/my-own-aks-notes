# 1-go to Azure Active Directory / Register the application
    tdmr-dev-deploy-appreg

# 2-Record the application and tenant IDs
    Application (client) ID:9d2da157-a581-4b92-8520-84599d995f3b
    Directory (tenant) ID:b6ec61f1-75b3-4a86-8ccc-fe9d4cc785bd
    Object ID:6d734e98-a615-4501-9073-b0c5e5c1800f

# 3-Create a client secret
    Value: -------------------------
    Enter this value as the Service Principal Key in Azure DevOps

# 4: Assign an RBAC role
    Contributor
    tdmr-dev-deploy-appreg

# 5: Enter the connection details
    Identity type: app registration or managed identity
    Identity type: secret
    Environment: azure cloud
    Subscription ID: abdb38d1-d80a-40c6-a158-f152d3dfb285
    Subscription name: Azure subscription 1
    Application (client) ID: 9d2da157-a581-4b92-8520-84599d995f3b
    Directory (tenant) ID: b6ec61f1-75b3-4a86-8ccc-fe9d4cc785bd
    Credential: Service principal key
    Client secret: -------------------------
    verify
