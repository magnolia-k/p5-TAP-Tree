use 5.006;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME             => 'TAP::Tree',
    AUTHOR           => q{magnolia <magnolia.k@me.com>},
    VERSION_FROM     => 'lib/TAP/Tree.pm',
    ABSTRACT_FROM    => 'lib/TAP/Tree.pm',
    LICENSE          => 'perl_5',
    MIN_PERL_VERSION => 5.010001,

    CONFIGURE_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.66,
    },

    BUILD_REQUIRES => {
        'ExtUtils::MakeMaker' => 6.66,
    },

    META_MERGE      => {
        "meta-spec" => { version => 2 },

        "resources" => {
            "homepage" => "https://github.com/magnolia-k/p5-TAP-Tree",

            "bugtracker" => {
                "web" => "https://github.com/magnolia-k/p5-TAP-Tree/issues",
            },

            "repository" => {
                "type" => "git",
                "url"  => "https://github.com/magnolia-k/p5-TAP-Tree.git",
                "web"  => "https://github.com/magnolia-k/p5-TAP-Tree",
            },
        },
    },


    );