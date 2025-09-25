const { GoogleAuth } = require('google-auth-library');

async function getAccessToken() {
  const auth = new GoogleAuth({
    keyFilename: 'C:\\Users\\ACER\\Desktop\\SES\\L400-SEM1\\FIRST_SEM\\FinalYearProject\\Code\\patient_monitor_backend_patient\\service-account-file.json', // Correct path
    scopes: ['https://www.googleapis.com/auth/firebase.messaging'], // Required scopes
  });
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  console.log(token.token); // This is your access token
}

getAccessToken().catch(console.error);