require('../../bower_components/angular/angular.js')
require('../../bower_components/angular-route/angular-route.js')
require('../../bower_components/angular-sanitize/angular-sanitize.js')
require('../../bower_components/angular-animate/angular-animate.js')
require('../../bower_components/angular-cookies/angular-cookies.js')
require('../../bower_components/fhir.js/dist/ngFhir.js')
window.CodeMirror = require('../../bower_components/codemirror/lib/codemirror.js')
require('../../bower_components/angular-ui-codemirror/ui-codemirror.js')
require('../../bower_components/codemirror/lib/codemirror.css')

module.exports = angular.module 'fhirface', [
  'ngCookies',
  'ngAnimate',
  'ngSanitize',
  'ngRoute',
  'ui.codemirror',
  'app-fhir',
  'ng-fhir'
]
