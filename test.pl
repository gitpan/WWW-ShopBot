use Test;
BEGIN { plan tests => 3 };
use WWW::ShopBot qw/list_drivers/;
ok(1);
$bot = new WWW::ShopBot(drivers => [ '_test', ]);
push @pool,
    $bot->query(
		product => 'ibm',
		price => [100, 2000],
		),
    $bot->query(
		product => 'ibm',
		);

ok($pool[2]->{price}, 123);
ok($pool[4]->{product}, 'qwer');
