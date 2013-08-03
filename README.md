HSL
===

Haskell command line text processor

Tool to quickly compile and run haskell streaming text processors on the
command line.

Features a powerful way of working quickly with JSON.

Examples
========

    > echo '!LSH olleH'  | hsl 'B.reverse . head'
    Hello HSL!

    > printf "hello\nworld\n" | hsl 'take 2 . repeat . filter (B.isPrefixOf "w")'
    world
    world

    > cat src/HSL/* | hsl 'take 5 . reverse . hist . B.words . B.concat'
    41	->
    37	=
    20	where
    17	tb
    17	Scalar

    > echo '{"a": 1}' | hsl 'json tI "a"'
    1

    > echo '[1,2]' | hsl 'json [tI] ""'
    1
    2

    > echo '{"a": "Hello", "b": ["", "World"]}' | hsl 'json2 (tS, tS) "a" "b 1"'
    Hello	World

Installing
==========

    > git clone 'https://github.com/ssadler/hsl.git' && cd hsl
    > # Install dependencies... You probably already have them (?)
    > echo 'alias hsl="'`pwd`'/hsl"' >> ~/.bashrc

Contributing
============

Open to contributions!
