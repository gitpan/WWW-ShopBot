package WWW::ShopBot::_test;

sub new { bless $_[1], $_[0] }

sub query {
    shift;
    [
     {
	 product => 'aaa',
	 price => 1234,
     },
     {
	 product =>'asdf',
	 price   => 123,
     },
     {
	 product => 'qwer',
	 price => 12345,
     },
     ]
}

1;
