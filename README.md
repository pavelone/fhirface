Fhirface
=========

## Description


### [Live Demo](http://try-fhirplace.hospital-systems.com/fhirface/index.html#/)

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

```
git clone https://github.com/fhirbase/fhirface
cd fhirface
# install npm modules
npm install
# install bower packages
`npm bin`/bower install
#build app into <dir-to-build> directory
env PREFIX=<dir-to-build> `npm bin`/grunt build
```

After building you can copy build directory into your web server
directory and open index.html file.


## Implementation details

* Written in [coffescript](http://coffeescript.org/)
* and [less](http://lesscss.org/)
* using [angularjs](https://angularjs.org/)
* and [twitter bootstrap](http://getbootstrap.com/)
* manage node packages with npm & assets with bower
* automate tasks with grunt


## Directory structure

```
coffee/       # code
less/         # styles
lib/          # bower  cache
views/        # angularjs templates
.bowerrc
.gitignore
Gruntfile.js  # grunt tasks
README.md
bower.json    # bower packages config
index.html    # main page (entry point)
package.json  # npm packages
```

## TODO

* tags support
* authorization
* profile visualization

## Contribution

Be free make feature requests & report bugs.

* Issues by [github](https://github.com/fhirbase/fhirface/issues)
* Fixes by pull-requests
