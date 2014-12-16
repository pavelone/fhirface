BASE_URL = 'http://172.17.0.9:7000'
module.exports = ()->
  BASE_URL || "#{window.location.protocol}//#{window.location.host}"
