const { GoogleAuth } = require('google-auth-library');

async function getAccessToken() {
  try {
    let credentials;
    
    if (process.env.GOOGLE_SERVICE_ACCOUNT_JSON) {
      credentials = JSON.parse(process.env.GOOGLE_SERVICE_ACCOUNT_JSON);
    } else if (require('fs').existsSync('./service-account-file.json')) {
      credentials = require('./service-account-file.json');
    } else {
      throw new Error('No service account credentials found');
    }

    const auth = new GoogleAuth({
      credentials: credentials,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });
    
    const client = await auth.getClient();
    const token = await client.getAccessToken();
    
    console.log(JSON.stringify({
      token: token.token,
      expiresAt: token.res?.data?.expiry_date
    }));
  } catch (error) {
    console.error(JSON.stringify({ error: error.message }));
    process.exit(1);
  }
}

getAccessToken().catch(console.error);
