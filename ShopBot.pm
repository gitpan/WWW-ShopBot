package WWW::ShopBot;
use 5.006;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(list_drivers);
our $VERSION = '0.02';
use Carp qw(confess);

sub new {
    my $pkg = shift;
    my $arg = ref($_[0]) ? shift : {@_};
    my $line = (caller(0))[2];
    bless {
	drivers   => (($arg->{drivers} ? $arg->{drivers} : $arg->{merchants}) || die "No drivers given at line $line in $0\n"),
	pick      => $arg->{pick} || [ 'product', 'price' ],
	proxy     => $arg->{proxy},
    }, $pkg;
}

# discard unwanted information
sub sift {
    caller eq __PACKAGE__ or die "It's private method.\n";
    my($result, $criteria) = @_;

    foreach my $r (@{$result}){
	unless( $r->{product} && $r->{price} ){
	    $r = {};
	    next;
	}

	# lower bound
	if(defined $criteria->{price}->[0]){
	    if($r->{price} < $criteria->{price}->[0]){
		$r = {};
		next;
	    }
	}

	# upper bound
	if(defined $criteria->{price}->[0]){
	    if($r->{price} > $criteria->{price}->[1]){
		$r = {};
		next;
	    }
	}

	# other filters
	foreach my $f (keys %{$criteria}){
	    next if $f =~ /^product$/io;
	    next if $f =~ /^price$/io;
	    unless( $criteria->{$f}->($r->{$f}) ){
		$r = {};
		next;
	    }
	}
    }
}

sub query {
    my $pkg = shift;
    my $criteria = ref($_[0]) ? $_[0] : @_ == 1 ? {product => $_[0]} : {@_};
    my (@pool, $result);
    foreach my $driver (@{$pkg->{drivers}}){
	$driver =~ s/^WWW::ShopBot:://;
	eval 'use WWW::ShopBot::'.$driver.';
	$result = WWW::ShopBot::'.$driver.'::query( $criteria->{product} );
	sift($result, $criteria, $driver);
	push @pool, grep { scalar %$_ } @$result;';
	confess "Driver error: $driver\n$@" if $@;
    }
    return sort {$a->{price} <=> $b->{price}} @pool;
}

sub list_drivers {
    my @driver = sort grep {$_} map { map{s,/,::,g} map{print $_; m,WWW/ShopBot/(.+)\.pm,;$1} glob "$_/WWW/ShopBot/*pm" } @INC;
    wantarray ? @driver : \@driver;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

WWW::ShopBot - Price comparison agent

=head1 SYNOPSIS

  use WWW::ShopBot;
  $bot = new WWW::ShopBot( drivers => \@drivers );
  $bot->query($product);

=head1 DESCRIPTION

This module is a shopping agent which can fetch products' data and sort them by the price. Users can also write drivers to extend its functionality.

=head2 Set up a bot

  $bot = new WWW::ShopBot(
    # Load drivers for merchants
    # It will scan through directories for drivers
    drivers   => \@drivers,

    # Recognized entries in an item's data
    # 'product' and 'price' are the default.
    pick      => [ 'product', 'price', 'desc' ],
    
    proxy => 'http://foo.bar:1234/,
    );


=head2 Look for product

Query will be sent to the given hosts.

  $result = $bot->query('some product');

Or more specifically, you can do this.

  $result = $bot->query(
			product => 'some product',

			# Choose items whose prices are between
			# an interval
			price => [ $lower_bound, $upper_bound ],

			# You can use a self-defined filter to
			# decide whether to take this item or not.
			desc => \&my_desc_filter,
			);

Then, it will returns a list of products' data.

=head2 List drivers

This module also exports a tool for listing existent merchant drivers in computer.

  print join $/, list_drivers;

=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut
