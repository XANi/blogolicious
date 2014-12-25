package Blogolicious::Plugin::Spam;

use common::sense;

use namespace::clean;
use Moo;

use Log::Any qw($log);
use List::Util qw(sum);
use Module::Load;

has 'spam_threshold' => (
    is => 'ro',
    isa => sub {
        if ($_[0] <= 0) {
            croak("spam threshold have to be higher than 0");
        }
    },
    default => sub { 0.8 },
);

has 'moderate_threshold' => (
    is => 'ro',
    isa => sub {
        if ($_[0] <= 0) {
            croak("spam threshold have to be higher than 0");
        }
    },
    default => sub { 0.5 },
);

has 'plugins' => (
    is => 'ro',
    isa => sub {},
    default => sub{ {plugin => 'ham', config => {}, weight => 1 }},
);

sub BUILD {
    my $self = shift;
    if (ref($self->plugins) eq 'ARRAY') {
        for my $plugin( @{ $self->plugins } ) {
            $self->add_plugin($plugin->{'plugin'},$plugin->{'config'},$plugin->{'weight'});
        }
    }
}



sub add_plugin {
    my $self = shift;
    my $plugin = ucfirst(shift);
    my $config = shift;
    my $weight = shift;
    $weight ||= 0;
    if($plugin !~ /::/) {
        $plugin = "Blogolicious::Plugin::Spam::$plugin";
    }
    load $plugin;
    if (defined $self->{'plugin'}{$plugin}) {
        $log->warn("Spam plugin $plugin loaded twice!");
    }
    $self->{'plugin'}{$plugin} = $plugin->new($config);
    $self->{'plugin_weight'}{$plugin} = $weight;
    return;
};

sub rate_raw {
    my $self = shift;
    my $data = shift;
    if (!defined($self->{'plugin'})) {
        $log->warn("you might want to configure some spam plugins first");
        return 0;
    }
    my $weighted_rating;
    my $weight_sum = sum(values %{ $self->{'plugin_weight'} });
    if ($weight_sum <= 0) { croak("Plugin weight should sum to more than 0")}
    my $rate_sum;
    foreach my $plugin (keys %{ $self->{'plugin'} }) {
        $rate_sum += $self->{'plugin'}{$plugin}->rate($data) * $self->{'plugin_weight'}{$plugin};
    }
    my $rate = $rate_sum / $weight_sum;
    $log->debug("spam rating: $rate");
    return $rate;
}


sub rate {
    my $self = shift;
    my $headers = shift;
    my $data = shift;
    my $rating = $self->rate_raw($data);
    if ($rating < $self->moderate_threshold) {
        return 0;
    }
    elsif  ($rating < $self->spam_threshold) {
        return 1;
    } else {
        return 2;
    }
};

1;
__END__;

=head1 NAME

Blogolicious::Plugins::Spam - spam detection plugin

=head1 DESCRIPTION

Common wrapper for various spam plugins. Will return spam, ham or unsure (to moderate) based on loaded sub-plugins and their weight

=head1 USAGE

=over

=item B<$s->rate($data)>

Return rating of a given post.  0 - HAM, >= 1 - unsure (to moderation), 2 >= - SPAM
