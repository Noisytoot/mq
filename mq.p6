#!/usr/bin/env perl6
use v6;
use XML;

my Str $log-file;

if %*ENV<MQ_LOG>:exists {
    $log-file = %*ENV<MQ_LOG>;
} else {
    $log-file = "$*HOME/.mq/log.xml";
}
unless $log-file.IO.e {
    spurt $log-file, make-xml('log', \('meta', :version<1>)).Str;
}
my XML::Document $log = from-xml-file($log-file);

sub MAIN {
    $log[3].append(make-xml('group',
                            :actual-length<1>,
                            :original-length<2>,
                            :max<3>,
                            :timestamp<4>,
                            :score<5>,
                            :level<6>
                           )
                  );
    say "Üks!";
    spurt $log-file, $log.Str;
    say "Kaks!";
}
