use Test;
BEGIN { plan tests => 6 };
use WWW::ShopBot qw/list_drivers list_drivers_paths/;
ok(1);
ok(join(q//, list_drivers), qr/_test::_test/);
ok(join(q//, list_drivers_paths), qr,WWW/ShopBot/_test.pm,);

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
ok($pool[3]->{driver}, '_test');
