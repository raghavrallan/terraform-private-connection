const express = require('express');
const { DefaultAzureCredential } = require('@azure/identity');
const { SecretClient } = require('@azure/keyvault-secrets');
const { BlobServiceClient } = require('@azure/storage-blob');
const { Connection, Request } = require('tedious');

const app = express();
const PORT = process.env.PORT || 8080;

app.use(express.json());

// Azure Managed Identity Credential
const credential = new DefaultAzureCredential();

// Environment variables (injected by Container App)
const KEY_VAULT_URL = process.env.KEY_VAULT_URL;
const STORAGE_ACCOUNT_NAME = process.env.STORAGE_ACCOUNT_NAME;
const SQL_SERVER = process.env.SQL_SERVER;
const SQL_DATABASE = process.env.SQL_DATABASE;

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'healthy', service: 'container-app-api' });
});

// Get secret from Key Vault
app.get('/api/keyvault/test', async (req, res) => {
  try {
    const secretClient = new SecretClient(KEY_VAULT_URL, credential);
    const secret = await secretClient.getSecret('storage-account-name');

    res.json({
      success: true,
      message: 'Successfully retrieved secret from Key Vault',
      secretName: secret.name,
      // Don't expose the actual secret value in production!
      secretExists: !!secret.value
    });
  } catch (error) {
    console.error('Key Vault error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Test Storage Account connectivity
app.get('/api/storage/test', async (req, res) => {
  try {
    const blobServiceClient = new BlobServiceClient(
      `https://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net`,
      credential
    );

    // List containers
    const containers = [];
    for await (const container of blobServiceClient.listContainers()) {
      containers.push(container.name);
    }

    res.json({
      success: true,
      message: 'Successfully connected to Storage Account',
      storageAccount: STORAGE_ACCOUNT_NAME,
      containerCount: containers.length,
      containers: containers
    });
  } catch (error) {
    console.error('Storage error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Upload blob to storage
app.post('/api/storage/upload', async (req, res) => {
  try {
    const { containerName, blobName, content } = req.body;

    if (!containerName || !blobName || !content) {
      return res.status(400).json({
        success: false,
        error: 'containerName, blobName, and content are required'
      });
    }

    const blobServiceClient = new BlobServiceClient(
      `https://${STORAGE_ACCOUNT_NAME}.blob.core.windows.net`,
      credential
    );

    const containerClient = blobServiceClient.getContainerClient(containerName);

    // Create container if it doesn't exist
    await containerClient.createIfNotExists({ access: 'blob' });

    const blockBlobClient = containerClient.getBlockBlobClient(blobName);
    await blockBlobClient.upload(content, content.length);

    res.json({
      success: true,
      message: 'Blob uploaded successfully',
      container: containerName,
      blob: blobName,
      url: blockBlobClient.url
    });
  } catch (error) {
    console.error('Upload error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Test SQL Database connectivity
app.get('/api/database/test', async (req, res) => {
  try {
    // Get access token for SQL using managed identity
    const tokenResponse = await credential.getToken('https://database.windows.net/');

    const config = {
      server: SQL_SERVER,
      authentication: {
        type: 'azure-active-directory-access-token',
        options: {
          token: tokenResponse.token
        }
      },
      options: {
        database: SQL_DATABASE,
        encrypt: true,
        port: 1433
      }
    };

    const connection = new Connection(config);

    connection.on('connect', (err) => {
      if (err) {
        console.error('SQL connection error:', err);
        res.status(500).json({
          success: false,
          error: err.message
        });
        return;
      }

      const request = new Request('SELECT @@VERSION AS version', (err, rowCount, rows) => {
        if (err) {
          console.error('SQL query error:', err);
          res.status(500).json({
            success: false,
            error: err.message
          });
        } else {
          res.json({
            success: true,
            message: 'Successfully connected to SQL Database',
            server: SQL_SERVER,
            database: SQL_DATABASE,
            rowCount: rowCount
          });
        }
        connection.close();
      });

      connection.execSql(request);
    });

    connection.connect();

  } catch (error) {
    console.error('Database error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Call Function App (private service)
app.get('/api/function/call', async (req, res) => {
  try {
    const FUNCTION_APP_URL = process.env.FUNCTION_APP_URL;

    if (!FUNCTION_APP_URL) {
      return res.status(500).json({
        success: false,
        error: 'FUNCTION_APP_URL not configured'
      });
    }

    // Get access token for calling Function App
    const tokenResponse = await credential.getToken('https://management.azure.com/');

    const response = await fetch(`${FUNCTION_APP_URL}/api/process`, {
      method: 'GET',
      headers: {
        'Authorization': `Bearer ${tokenResponse.token}`,
        'Content-Type': 'application/json'
      }
    });

    const data = await response.json();

    res.json({
      success: true,
      message: 'Successfully called Function App',
      functionResponse: data
    });
  } catch (error) {
    console.error('Function call error:', error);
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    service: 'Container App API',
    version: '1.0.0',
    endpoints: {
      health: '/health',
      keyVaultTest: '/api/keyvault/test',
      storageTest: '/api/storage/test',
      storageUpload: '/api/storage/upload (POST)',
      databaseTest: '/api/database/test',
      functionCall: '/api/function/call'
    }
  });
});

app.listen(PORT, '0.0.0.0', () => {
  console.log(`Container App API listening on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});
