#!/bin/bash

cpan
install YAML
install Module::Build
install Data::ICal
install Date::ICal
# install Authen::Captcha
install HTTP::Tiny; # for recaptcha
install Net::SSLeay; # for reaptcha
install Captcha::reCAPTCHA
install Apache::Session
install Geo::Gpx
install XML::RSS
install XML::RSS::Parser
#install DBI
#install DBD::mysql
#install Cache::Memcached
install Net::DNS
install LWP::Parallel

