Fhirface
=========

## [Live Demo](http://try-fhirplace.hospital-systems.com/fhirface/index.html#/)

[fhirplace](https://github.com/fhirbase/fhirplace) on server side.

## Description

Generic UI for [FHIR](http://www.hl7.org/implement/standards/fhir/) servers.

`Fhirface` is byproduct of [fhirplace](https://github.com/fhirbase/fhirplace) open source FHIR server implementation.
It can be used with any FHIR compliant server (support of json format required).

Features:

* Visualize conformance
* Search resources
* Profile information
* Create, Update, Delete resources

## Installation

`nodejs` is required for build.
We recommend install it using [nvm](https://github.com/creationix/nvm/blob/master/README.markdown)

```sh
git clone https://github.com/fhirbase/fhirface
cd fhirface
# install npm modules
npm install
# build app into ./dist
env BASEURL=http://fhirplace.health-samurai.io npm run-script build

# run def server
env PORT=8080 BASEURL=http://fhirplace.health-samurai.io npm start

# publish
env PORT=8080 BASEURL=http://fhirplace.health-samurai.io npm run-script deploy
```

After building you can copy build directory into your web server
directory and open index.html file.

### Run with OAuth2

Asume [Fhirwall][] running on `http://localhost:3000/fhir` and
application it self running on `http://localhost:8080/#/redirect`.

```sh
nvm use 0 \
  && env \
     PORT=8080 \
     BASEURL='http://localhost:3000/fhir' \
     OAUTH_CLIENT_ID='99a093ae-a4ed-4c4c-b6c4-c768342604ea' \
     OAUTH_CLIENT_SECRET='2fe0628e-669f-4aa5-b221-c44d926c53e1' \
     OAUTH_REDIRECT_URI='http://localhost:8080/#/redirect' \
     OAUTH_SCOPE='all' \
     OAUTH_RESPONSE_TYPE='token'
     OAUTH_AUTHORIZE_URI='http://localhost:3000/oauth/authorize' \
     npm start
```

[Fhirwall]: https://github.com/fhirbase/fhirwall

## Service

> All premium services from developers of Fhirbase projects
> should be requested from Choice Hospital Systems (http://Choice-HS.com)


## Implementation details

* Written in [coffescript](http://coffeescript.org/)
* and [less](http://lesscss.org/)
* using [angularjs](https://angularjs.org/)
* and [twitter bootstrap](http://getbootstrap.com/)
* manage node packages with npm & assets with bower
* automate tasks with grunt


## TODO

* authorization
* better profile visualization

## Contribution

Be free make feature requests & report bugs.

* Issues by [github](https://github.com/fhirbase/fhirface/issues)
* Fixes by pull-requests
