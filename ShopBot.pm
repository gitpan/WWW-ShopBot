package WWW::ShopBot;
use 5.006;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(list_drivers list_drivers_paths);
our $VERSION = '0.06';
use Carp qw(confess);

sub new {
    my $pkg = shift;
    my $arg = ref($_[0]) ? shift : {@_};
    my $line = (caller(0))[2];
    bless {
	drivers   => (($arg->{drivers} ? $arg->{drivers} : $arg->{merchants}) || die "No drivers given at line $line in $0\n"),
	proxy     => $arg->{proxy},
	login     => $arg->{login},
	jar       => $arg->{jar} || "$ENV{HOME}/.www-shopbot.cookies.txt",
    }, $pkg;
}

# discard unwanted information
sub sift {
    caller eq __PACKAGE__ or die "It's private method.\n";
    my($result, $criteria, $driver) = @_;

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
	    next if ref($criteria->{$f}) ne 'CODE';
	    unless( $criteria->{$f}->($r->{$f}) ){
		$r = {};
		next;
	    }
	}
	$r->{driver} = $driver;
    }
}

sub query {
    my $pkg = shift;
    my $criteria = ref($_[0]) ? $_[0] : @_ == 1 ? {product => $_[0]} : {@_};
    my (@pool, $result, $user, $pass);
    foreach my $driver (@{$pkg->{drivers}}){
	$driver =~ s/^WWW::ShopBot:://o;
	$user = $pkg->{login}->{$driver}->{user};
	$pass = $pkg->{login}->{$driver}->{pass};
	eval 'use WWW::ShopBot::'.$driver.';
        my $bot = new WWW::ShopBot::'.$driver.'
                       ({
                          product => $criteria->{product},
                          price => $criteria->{price},
                          proxy => $pkg->{proxy},
                          user => $user,
                          pass => $pass,
                          jar => $pkg->{jar},
                       });
	$result = $bot->query;
	sift($result, $criteria, $driver);
	push @pool, grep { scalar %$_ } @$result;';
	confess "Driver error: $driver\n$@" if $@;
    }
    wantarray ? (sort {$a->{price} <=> $b->{price}} @pool) : [sort {$a->{price} <=> $b->{price}} @pool];
}

use File::Find::Rule;
sub list_drivers {
    my @files = 
	sort grep{$_} grep{$_ ne 'Driver'} map{s,/,::,go;$_}
    map{m,WWW/ShopBot/(.+)\.pm,o?$1:''}
  File::Find::Rule->file()->name( '*.pm' )->in( map{$_.'/WWW/ShopBot/'} @INC );
    return wantarray ? @files : \@files;
}

sub list_drivers_paths {
    my @files = 
	sort grep{$_} grep{$_ !~ 'WWW/ShopBot/Driver'}
  File::Find::Rule->file()->name( '*.pm' )->in( map{$_.'/WWW/ShopBot/'} @INC );
    return wantarray ? @files : \@files;
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

    proxy => 'http://foo.bar:1234/,

    # Set up account information
    login =>
       {
          driver_1 => {
                         user => 'abuser',
                         pass => 'cannot pass',
                      },
        },

    # cookie jar
    jar => "$ENV{HOME}/.www-shopbot.cookies.txt",
    );


=head2 Look for product

Query will be sent to the given hosts.

  @result = $bot->query('some product');

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

Then, it will returns a list or a listref of products' data.

=head2 List drivers

This module also exports tools for listing existent merchant drivers in computer.

=over 2

=item * Simply print drivers' names

  use WWW::ShopBot qw(list_drivers);
  print join $/, list_drivers;


=item * Print drivers' names followed by their paths

  use WWW::ShopBot qw(list_drivers_paths);
  print join $/, list_drivers_paths;

=back

=head1 CAVEAT

Alpha version.

=head1 COPYRIGHT

xern E<lt>xern@cpan.orgE<gt>

This module is free software; you can redistribute it or modify it under the same terms as Perl itself.

=cut
