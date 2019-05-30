#!/usr/bin/env perl6
use v6;
use Config::TOML;
use Terminal::ANSIColor;

my Str $config-file = "$*HOME/.mq/config.toml"; # Change this to change config file location, written in TOML 0.4.0
my Hash %config = from-toml($config-file.IO.slurp);
my Int $group = %config<mq><group>;
my Int $score;

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

sub MAIN(Str $mode, Int $max) {
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
                    }
                } else {
                    if $result == $n1 - $n2 {
                        correct;
                        $score++;
                    } else {
                        wrong $n1 - $n2;
                    }
                }
            }
            score $score, $group;
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
                    }
                } else {
                    if $result == $divanswer {
                        correct;
                        $score++;
                    } else {
                        wrong $divanswer;
                    }
                }
            }
            score $score, $group;
        }
    }
}
