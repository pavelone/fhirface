app = require('./module')

app.config ($routeProvider) ->
    $routeProvider
      .when '/',
        templateUrl: '/views/conformance.html'
        controller: 'ConformanceCtrl'
      .when '/authorization',
        templateUrl: '/views/authorization.html'
        controller: 'AuthorizationCtrl'
      .when '/redirect',
        templateUrl: '/views/authorization_redirect.html'
        controller: 'AuthorizationRedirectCtrl'
      .when '/conformance',
        templateUrl: '/views/conformance.html'
        controller: 'ConformanceCtrl'
      .when '/resources/Any',
        templateUrl: '/views/index.html'
        controller: 'IndexCtrl'
      .when '/resources/Any/history',
        templateUrl: '/views/history.html'
        controller: 'HistoryCtrl'
      .when '/resources/Any/tags',
        templateUrl: '/views/tags.html'
        controller: 'TagsCtrl'
      .when '/resources/Any/transaction',
        templateUrl: '/views/transaction.html'
        controller: 'TransactionCtrl'
      .when '/resources/Any/document',
        templateUrl: '/views/document.html'
        controller: 'DocumentCtrl'
      .when '/resources/:resourceType',
        templateUrl: '/views/index.html'
        controller: 'ResourcesIndexCtrl'
      .when '/resources/:resourceType/history',
        templateUrl: '/views/history.html'
        controller: 'ResourcesHistoryCtrl'
      .when '/resources/:resourceType/tags',
        templateUrl: '/views/tags.html'
        controller: 'ResourcesTagsCtrl'
      .when '/resources/:resourceType/new',
        templateUrl: '/views/new.html'
        controller: 'ResourcesNewCtrl'
      .when '/resources/:resourceType/:id',
        templateUrl: '/views/show.html'
        controller: 'ResourceCtrl'
      .when '/resources/:resourceType/:id/history',
        templateUrl: '/views/history.html'
        controller: 'ResourceHistoryCtrl'
      .when '/resources/:resourceType/:id/tags',
        templateUrl: '/views/tags.html'
        controller: 'ResourceTagsCtrl'
      .otherwise
        redirectTo: '/'
