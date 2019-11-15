#!/usr/bin/env perl6

# Copyright © 2019 Noisytoot
# mq is a program that asks you maths questions

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>

use v6;
use Config::TOML;
use Terminal::ANSIColor;
use Readline;

constant @version = 1, 5, 0;
constant $version = "@version[0].@version[1].@version[2]";
my Bool %*SUB-MAIN-OPTS = :named-anywhere;

my Str $config-file;
my Str $config-dir;
if %*ENV<MQ_CONFIG_DIR>:exists {
    $config-dir = %*ENV<MQ_CONFIG_DIR>;
} else {
    $config-dir = "$*HOME/.mq"
}

if %*ENV<MQ_CONFIG>:exists {
    $config-file = %*ENV<MQ_CONFIG>;
} else {
    $config-file = "$config-dir/config.toml";
}
my Hash %config;
if $config-file.IO.e {
    %config = from-toml($config-file.IO.slurp);
    %config<mq><group> = 20 unless %config<mq><group>:exists;
    %config<mq><max> = 10 unless %config<mq><max>:exists;
} else {
    %config = mq => { group => 20, max => 10 };
}
my Int $config-group = %config<mq><group>;
my Int $original-group = $config-group;
my Int $score = 0;
my Str $log-file;
if %*ENV<MQ_LOG>:exists {
    $log-file = %*ENV<MQ_LOG>;
} else {
    $log-file = "$config-dir/log.slf";
}
mkdir $config-dir unless $config-dir.IO.e;
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
    my Readline $readline = Readline.new();
    return $readline.readline(colored("What is $n1 $operator $n2? ", "bold cyan")).Int;
}

sub score(Int $score, Int $group) {
    say colored("Score: $score out of $group", "bold yellow");
}

sub slf-write(Str $file, DateTime $timestamp, Int $level, Int $max, Int $actual-length, Int $original-length, Int $score) {
    spurt $file, "R $timestamp $level $max $actual-length $original-length $score\n", :append;
}

sub progress(Int $score, Int $group) {
    my Int $left = $group - $score;
    say colored("Progress: $score done, $left left", "bold yellow");
}

sub USAGE {
    say "Usage: $*PROGRAM-NAME [--disable-log] [--group=<group-length>] <mode> <max>";
    say "Valid modes: level1 (addition, subtraction), level2 (multiplication, division), get-group (print group length), get-max (print maximum)";
    say "mq version $version\n";
    say "Config dir location is set in the environment variable \$MQ_CONFIG_DIR, the default is ~/.mq, the following variables override this:";
    say "Log file location is set in the environment variable \$MQ_LOG, the default is ~/.mq/log.slf";
    say "Configuration file location is set in the environment variable \$MQ_CONFIG, the default is ~/.mq/config.toml\n";
    say "Example configuration file:";
    say colored("[", "italic cyan") ~ colored("mq", "italic yellow") ~ colored("]", "italic cyan");
    say colored("group", "italic magenta") ~ " " ~ colored("=", "italic cyan") ~ " " ~ colored("20", "italic yellow");
    say colored("max", "italic magenta") ~ " " ~ colored("=", "italic cyan") ~ " " ~ colored("10", "italic yellow");
}

sub MAIN(Str $mode, Int $max = %config<mq><max>, Bool :$disable-log, Int :$group = $config-group) {
    $original-group = $group unless $group == $original-group;
    die "Maximum must be more than 2" if $max < 3;
    die "Maximum must be more than 0" if $group < 1;
    
    my Int $level;
    if $mode eq "level1" {
        $level = 1;
    } elsif $mode eq "level2" {
        $level = 2;
    }

    given $mode {
        say "Group length: $config-group" when "get-group";
        say "Max: %config<mq><max>" when "get-max";
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
                progress $score, $original-group;
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
                progress $score, $original-group;
            }
            score $score, $group;
            slf-write $log-file, DateTime.now(), $level, $max, $group, $original-group, $score unless $disable-log;
        }
    }
}
