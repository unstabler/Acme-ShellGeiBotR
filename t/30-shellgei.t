use v6.c;
use Test;
use lib 'lib';

use Acme::ShellGeiBotR;

plan 3;

my $dummy-bot = ShellGeiBotR.new(host => '', token => '');
my $toot = {
    'id' => '300',
    'content' => q{<p>echo 'Hello, World' #シェル芸</p>},
    'account' => {
        'id' => '3',
        'username' => 'cheesekun',
        'display_name' => 'cheesekun'
    },
    'tags' => [
        { 'name' => 'シェル芸' }
    ]
};

ok $dummy-bot.needs-process($toot<tags>);

my $shellgei = Acme::ShellGeiBotR::ShellGei.new($toot);

ok $shellgei.reply-to eq '300';

ok $shellgei.script eq q{echo 'Hello, World' #シェル芸};

done-testing;
