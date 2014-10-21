package Net::Statsd::Client;
use Moo;
use Sub::Quote;

# ABSTRACT: Send data to StatsD / Graphite
our $VERSION = '0.30'; # VERSION
our $AUTHORITY = 'cpan:ARODLAND'; # AUTHORITY

use Etsy::StatsD 1.001;
use Net::Statsd::Client::Timer;

has 'prefix' => (
  is => 'ro',
  default => quote_sub q{''},
);

has 'sample_rate' => (
  is => 'ro',
  default => quote_sub q{1},
);

has 'host' => (
  is => 'ro',
  default => quote_sub q{'localhost'},
);

has 'port' => (
  is => 'ro',
  default => quote_sub q{8125},
);

has 'statsd' => (
  is => 'rw',
);

has 'warning_callback' => (
  is => 'rw',
);

sub BUILD {
  my ($self) = @_;
  $self->statsd(
    Etsy::StatsD->new($self->host, $self->port)
  );
}

sub _send {
  my ($self, $data, $sample_rate) = @_;

  $self->{statsd}->send(
    { "$self->{prefix}$data->{metric}" => "$data->{value}|$data->{type}" },
    ( defined($data->{sample_rate}) ? $data->{sample_rate} : $self->{sample_rate} ),
  );
}
    
sub increment {
  # ($self, $metric, [$sample_rate])
  $_[0]->_send({ metric => $_[1], value => 1, type => "c", sample_rate => $_[2] });
}

sub decrement {
  # ($self, $metric, [$sample_rate])
  $_[0]->_send({ metric => $_[1], value => -1, type => "c", sample_rate => $_[2] });
}

sub update {
  # ($self, $metric, $value, [$sample_rate])
  $_[0]->_send({ metric => $_[1], value => $_[2], type => "c", sample_rate => $_[3] });
}

sub timing_ms {
  # ($self, $metric, $time, [$sample_rate])
  $_[0]->_send({ metric => $_[1], value => $_[2], type => "ms", sample_rate => $_[3] });
}

sub gauge {
  # ($self, $metric, $value, [$sample_rate])
  $_[0]->_send({ metric => $_[1], value => $_[2], type => "g", sample_rate => $_[3] });
}

sub set_add {
  # ($self, $metric, $value, [$sample_rate])
  $_[0]->_send({ metric => $_[1], value => $_[2], type => "s", sample_rate => $_[3] });
}

sub timer {
  my ($self, $metric, $sample_rate) = @_;

  return Net::Statsd::Client::Timer->new(
    statsd => $self,
    metric => $metric,
    sample_rate => $sample_rate,
    warning_callback => $self->warning_callback,
  );
}

1;



=pod

=head1 NAME

Net::Statsd::Client - Send data to StatsD / Graphite

=head1 VERSION

version 0.30

=head1 SYNOPSIS

    use Net::Statsd::Client
    my $stats = Net::Statsd::Client->new(prefix => "service.frobnitzer.");
    $stats->increment("requests"); # service.frobnitzer.requests++ in graphite

    my $timer = $stats->timer("request_duration");
    # ... do something expensive ...
    $timer->finish;

=head1 ATTRIBUTES

=head2 host

B<Optional:> The hostname of the StatsD server to connect to. Defaults to
localhost.

=head2 port

B<Optional:> The port number to connect to. Defaults to 8125.

=head2 prefix

B<Optional:> A prefix to be added to all metric names logged throught his
object.

=head2 sample_rate

B<Optional:> A value between 0 and 1, determines what fraction of events
will actually be sent to the server. This sets the default sample rate,
which can be overridden on a case-by-case basis when sending an event (for
instance, you might choose to send errors at a 100% sample rate, but other
events at 1%).

=head2 warning_callback

B<Optional:> A function that will be called with a message if a C<timer>
is destroyed unexpectedly (see L<Net::Statsd::Timer>). If this is not set
the builtin C<warn> will be used.

=head1 METHODS

=head2 $stats->increment($metric, [$sample_rate])

Increment the named counter metric.

=head2 $stats->decrement($metric, [$sample_rate])

Decrement the named counter metric.

=head2 $stats->update($metric, $count, [$sample_rate])

Add C<$count> to the value of the named counter metric.

=head2 $stats->timing_ms($metric, $time, [$sample_rate])

Record an event of duration C<$time> milliseconds for the named timing metric.

=head2 $stats->timer($metric, [$sample_rate])

Returns a L<Net::Statsd::Client::Timer> object for the named timing metric.
The timer begins when you call this method, and ends when you call C<finish>
on the timer.

=head2 $stats->gauge($metric, $value, [$sample_rate])

Send a value for the named gauge metric. Instead of adding up like counters
or producing a large number of quantiles like timings, gauges simply take
the last value sent in any time period, and don't require scaling.

=head2 $statsd->set_add($metric, $value, [$sample_rate])

Add a value to the named set metric. Sets count the number of *unique*
values they see in each time period, letting you estimate, for example, the
number of users using a site at a time by adding their userids to a set each
time they load a page.

=head1 AUTHOR

Andrew Rodland <arodland@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Andrew Rodland.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

