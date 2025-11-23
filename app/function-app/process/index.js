const { DefaultAzureCredential } = require('@azure/identity');
const { SecretClient } = require('@azure/keyvault-secrets');
const { BlobServiceClient } = require('@azure/storage-blob');

// Initialize managed identity credential
const credential = new DefaultAzureCredential();

module.exports = async function (context, req) {
  context.log('Processing request in private Function App');

  try {
    const KEY_VAULT_URL = process.env.KEY_VAULT_URL;
    const STORAGE_ACCOUNT_NAME = process.env.STORAGE_ACCOUNT_NAME;

    // Get data from request
    const inputData = req.body || { message: 'No data provided' };

    // Process: Fetch secret from Key Vault
    let secretValue = null;
    try {
      const secretClient = new SecretClient(KEY_VAULT_URL, credential);
      const secret = await secretClient.getSecret('storage-account-name');
      secretValue = secret.value;
    } catch (error) {
      context.log.error('Key Vault error:', error.message);
    }

    // Process: Interact with Storage Account
    let storageStatus = 'Not accessed';
    try {
      const blobServiceClient = new BlobServiceClient(
        `https://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net`,
        credential
      );

      // List first container as a test
      const containerIterator = blobServiceClient.listContainers();
      const firstContainer = await containerIterator.next();

      if (firstContainer.value) {
        storageStatus = `Accessed - Found container: ${firstContainer.value.name}`;
      } else {
        storageStatus = 'Accessed - No containers found';
      }
    } catch (error) {
      context.log.error('Storage error:', error.message);
      storageStatus = `Error: ${error.message}`;
    }

    // Process the data (business logic here)
    const processedData = {
      ...inputData,
      processed: true,
      processedAt: new Date().toISOString(),
      processedBy: 'FunctionApp-PrivateBackend'
    };

    // Return response
    context.res = {
      status: 200,
      headers: {
        'Content-Type': 'application/json'
      },
      body: {
        success: true,
        message: 'Data processed successfully by private Function App',
        input: inputData,
        output: processedData,
        serviceInfo: {
          function: 'process',
          runtime: 'Node.js',
          managedIdentity: 'Enabled'
        },
        integrations: {
          keyVault: secretValue ? 'Connected' : 'Not accessed',
          storage: storageStatus
        }
      }
    };

  } catch (error) {
    context.log.error('Function error:', error);

    context.res = {
      status: 500,
      body: {
        success: false,
        error: error.message,
        message: 'Error processing request'
      }
    };
  }
};
