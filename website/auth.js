// ---------------------------
// Cognito Authentication
// ---------------------------
const COGNITO_CONFIG = {
    userPoolId: 'us-east-1_t3mevYpHr', // Latest User Pool
    clientId: '4qsdomknat4s4sb3u41mf6ult3', // Replace with actual Client ID from Cognito console
    region: 'us-east-1'
};

let currentUser = null;
let authToken = null;

// Initialize AWS SDK
AWS.config.region = COGNITO_CONFIG.region;

// ---------------------------
// Authentication Functions
// ---------------------------
function showAuthSection() {
    document.getElementById('authSection').style.display = 'block';
    document.getElementById('appSection').style.display = 'none';
}

function showAppSection() {
    document.getElementById('authSection').style.display = 'none';
    document.getElementById('appSection').style.display = 'block';
}

function signUp() {
    const email = document.getElementById('signupEmail').value;
    const password = document.getElementById('signupPassword').value;
    
    const userPool = new AmazonCognitoIdentity.CognitoUserPool({
        UserPoolId: COGNITO_CONFIG.userPoolId,
        ClientId: COGNITO_CONFIG.clientId
    });

    const attributeList = [
        new AmazonCognitoIdentity.CognitoUserAttribute({
            Name: 'email',
            Value: email
        })
    ];

    userPool.signUp(email, password, attributeList, null, function(err, result) {
        if (err) {
            alert('Sign up failed: ' + err.message);
            return;
        }
        alert('Sign up successful! Please check your email for verification code.');
        document.getElementById('verificationSection').style.display = 'block';
        currentUser = result.user;
    });
}

function confirmSignUp() {
    const code = document.getElementById('verificationCode').value;
    
    currentUser.confirmRegistration(code, true, function(err, result) {
        if (err) {
            alert('Verification failed: ' + err.message);
            return;
        }
        alert('Account verified! Please sign in.');
        document.getElementById('verificationSection').style.display = 'none';
    });
}

function signIn() {
    const email = document.getElementById('signinEmail').value;
    const password = document.getElementById('signinPassword').value;
    
    const userPool = new AmazonCognitoIdentity.CognitoUserPool({
        UserPoolId: COGNITO_CONFIG.userPoolId,
        ClientId: COGNITO_CONFIG.clientId
    });

    const userData = {
        Username: email,
        Pool: userPool
    };

    const cognitoUser = new AmazonCognitoIdentity.CognitoUser(userData);
    const authenticationData = {
        Username: email,
        Password: password
    };

    const authenticationDetails = new AmazonCognitoIdentity.AuthenticationDetails(authenticationData);

    cognitoUser.authenticateUser(authenticationDetails, {
        onSuccess: function(result) {
            authToken = result.getIdToken().getJwtToken();
            currentUser = cognitoUser;
            showAppSection();
            loadVoices(); // Reload voices with auth token
        },
        onFailure: function(err) {
            alert('Sign in failed: ' + err.message);
        }
    });
}

function signOut() {
    if (currentUser) {
        currentUser.signOut();
        currentUser = null;
        authToken = null;
        showAuthSection();
    }
}

// ---------------------------
// Check Authentication Status
// ---------------------------
function checkAuthStatus() {
    const userPool = new AmazonCognitoIdentity.CognitoUserPool({
        UserPoolId: COGNITO_CONFIG.userPoolId,
        ClientId: COGNITO_CONFIG.clientId
    });

    const cognitoUser = userPool.getCurrentUser();
    
    if (cognitoUser != null) {
        cognitoUser.getSession(function(err, session) {
            if (err) {
                showAuthSection();
                return;
            }
            if (session.isValid()) {
                authToken = session.getIdToken().getJwtToken();
                currentUser = cognitoUser;
                showAppSection();
                loadVoices();
            } else {
                showAuthSection();
            }
        });
    } else {
        showAuthSection();
    }
}

// Initialize on page load
$(document).ready(function() {
    checkAuthStatus();
});
