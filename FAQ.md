# FAQ

## How to start with OAuth2 proxy?

### Server kind

```sh
nvm use 0 \
  && PORT=53000 \
     BASEURL=http://localhost:3000/fhir \
     OAUTH_CLIENT_ID=99a093ae-a4ed-4c4c-b6c4-c768342604ea \
     OAUTH_CLIENT_SECRET=2fe0628e-669f-4aa5-b221-c44d926c53e1 \
     OAUTH_REDIRECT_URI=http://localhost:53000/#/redirect \
     OAUTH_SCOPE=all \
     OAUTH_RESPONSE_TYPE=code
     OAUTH_AUTHORIZE_URI=http://localhost:3000/oauth/authorize \
     OAUTH_ACCESS_TOKEN_URI=http://localhost:3000/oauth/access_token \
     npm start
```

### Client kind

```sh
nvm use 0 \
  && PORT=53000 \
     BASEURL=http://localhost:3000/fhir \
     OAUTH_CLIENT_ID=99a093ae-a4ed-4c4c-b6c4-c768342604ea \
     OAUTH_CLIENT_SECRET=2fe0628e-669f-4aa5-b221-c44d926c53e1 \
     OAUTH_REDIRECT_URI=http://localhost:53000/#/redirect \
     OAUTH_SCOPE=all \
     OAUTH_RESPONSE_TYPE=token
     OAUTH_AUTHORIZE_URI=http://localhost:3000/oauth/authorize \
     npm start
```
