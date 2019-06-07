#!/usr/bin/env perl6
use v6;
use Config::TOML;
use Terminal::ANSIColor;

my Int @version = 1, 1, 0;
my %*SUB-MAIN-OPTS = :named-anywhere;
my Str $config-file;
if %*ENV<MQ_CONFIG>:exists {
    $config-file = %*ENV<MQ_CONFIG>;
} else {
    $config-file = "$*HOME/.mq/config.toml";
}
my Hash %config = from-toml($config-file.IO.slurp);
my Int $group = %config<mq><group>;
my Int $original-group = $group;
my Int $score;
my Str $log-file;
if %*ENV<MQ_LOG>:exists {
    $log-file = %*ENV<MQ_LOG>;
} else {
    $log-file = "$*HOME/.mq/log.slf";
}
unless $log-file.IO.e {
    spurt $log-file, "SLF 1\nMQ_LOG 1\nH TIMESTAMP LEVEL MAX ACTUAL_LENGTH ORIGINAL_LENGTH SCORE\n";
}

sub correct {
    say colored("Correct", "bold green");
}

sub wrong(Int $correct) {
    say colored("Wrong", "bold red");
    say colored("Correct: $correct", "bold yellow");
}

sub ask(Int $n1, Str $operator, Int $n2) {
    return prompt(colored("What is $n1 $operator $n2? ", "bold cyan")).Int;
}

sub score(Int $score, Int $group) {
    say colored("Score: $score out of $group", "bold yellow");
}
sub slf-write(Str $file, DateTime $timestamp, Int $level, Int $max, Int $actual-length, Int $original-length, Int $score) {
    spurt $file, "R $timestamp $level $max $actual-length $original-length $score\n", :append;
}

sub USAGE {
    say "Usage: $*PROGRAM-NAME <mode> <max> -- <mode> should be level1 (addition, subtraction) or level2 (multiplication, division)";
    say "mq version @version[0].@version[1].@version[2]";
    say "Log file location is set in the environment variable \$MQ_LOG, or if that does not exist then in ~/.mq/log.slf";
    say "Configuration file location is set in the environment variable \$MQ_CONFIG, or if that does not exist then in ~/.mq/config.toml";
    say "Example configuration file:";
    say colored("[mq]", "italic magenta");
    say colored("group = 10", "italic magenta")
}

sub MAIN(Str $mode, Int $max, Bool :$disable-log) {
    if $max < 3 {
        say "Maximum must be more than 2";
        exit 1;
    }
    my Int $level;
    if $mode eq "level1" {
        $level = 1;
    } elsif $mode eq "level2" {
        $level = 2;
    }
    
    given $mode {
        when "level1" {
            loop (my Int $i = 0; $i < $group; $i++) {
                my Str $operator;
                if 2.rand.Int {
                    $operator = "+";
                } else {
                    $operator = "-";
                }
                my Int $n1 = (1..$max).rand.Int;
                my Int $n2 = (1..$max).rand.Int;
                my Int $result = ask($n1, $operator, $n2);
                if $operator eq "+" {
                    if $result == $n1 + $n2 {
                        correct;
                        $score++;
                    } else {
                        wrong $n1 + $n2;
                        $group++;
                    }
                } else {
                    if $result == $n1 - $n2 {
                        correct;
                        $score++;
                    } else {
                        wrong $n1 - $n2;
                        $group++;
                    }
                }
            }
            score $score, $group;
            slf-write $log-file, DateTime.now(), $level, $max, $group, $original-group, $score unless $disable-log;
        }
        when "level2" {
            loop (my Int $i = 0; $i < $group; $i++) {
                my Str $operator;
                if 2.rand.Int {
                    $operator = "*";
                } else {
                    $operator = "/";
                }
                my Int $n1 = (1..$max).rand.Int;
                my Int $n2 = (1..$max).rand.Int;
                my Int $divanswer;
                if $operator eq "/" {
                    $divanswer = $n1;
                    $n1 = $divanswer * $n2
                }
                my Int $result = ask($n1, $operator, $n2);
                if $operator eq "*" {
                    if $result == $n1 * $n2 {
                        correct;
                        $score++;
                    } else {
                        wrong $n1 * $n2;
                        $group++;
                    }
                } else {
                    if $result == $divanswer {
                        correct;
                        $score++;
                    } else {
                        wrong $divanswer;
                        $group++;
                    }
                }
            }
            score $score, $group;
            slf-write $log-file, DateTime.now(), $level, $max, $group, $original-group, $score unless $disable-log;
        }
    }
}
