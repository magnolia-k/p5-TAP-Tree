use strict;
use warnings;

use Test::Stream -V1;
use Test::Stream::Plugin::Exception;

require TAP::Tree;

plan(1);

like( dies { TAP::Tree->new }, qr/No required parameter/ );
