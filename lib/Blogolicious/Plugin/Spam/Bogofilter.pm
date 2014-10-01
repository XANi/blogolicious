package Blogolicious::Plugin::Spam::Bogofilter;

use common::sense;
use Moo;

use Log::Any;
use IPC::Open3;
use Carp qw(croak);
sub rate {
     my $self = shift;
     my $arg = shift;
     my $data = $self->_format_data($arg);
     my $args = ['-T', '-d', $self->db_dir ];
     if ($self->feedback) {
         push @$args, '-u';
     }
     my ($result, $rating) = $self->run_bogofilter($args,$data);
     return $rating;
}

sub spam {
    my $self = shift;
    my $arg = shift;
    my $data = $self->_format_data($arg);
    my $args = ['-T', '-s', '-d', $self->db_dir ];
    my ($result, $rating) = $self->run_bogofilter($args,$data);
    return;
}

sub ham {
    my $self = shift;
    my $arg = shift;
    my $data = $self->_format_data($arg);
    my $args = ['-T', '-n', '-d', $self->db_dir ];
    my ($result, $rating) = $self->run_bogofilter($args,$data);
    return;
}

sub run_bogofilter {
    my $self = shift;
    my $args = shift;
    my $data = shift;
    my $pid = open3(my $in_fd, my $out_fd, undef, $self->bogofilter_path , @$args);
    print $in_fd $data;
    close $in_fd;
    my $out;
    while(<$out_fd>) {$out .= $_ ; print $out}
    waitpid( $pid, 0 );
    my $child_exit_status = $? >> 8;
    chomp ($out);
    return split(/\s+/,$out,2);
}


has 'bogofilter_path' => (
    is => 'ro',
    isa => sub {
        if (! -x $_[0]) {
            croak("$_[0] is not executable")
        }
    },
    default => sub {
        # this probably should search path via some clever module...
        my $bogofilter_bin = `which bogofilter`;
        chomp $bogofilter_bin;
        if ( ! -x $bogofilter_bin) {
            croak("Bogofilter bin [$bogofilter_bin] cant be found or not executable");
        }
        return $bogofilter_bin;
    }
);

has 'db_dir' => (
    is => 'ro',
#    isa => sub {};
    default => sub {'.bogofilter_db'},
);

has 'feedback' => (
    is => 'ro',
    default => sub {1},
);

sub _format_data {
    my $self = shift;
    my $data = shift;
    my $out;
    if (defined($data->{'headers'})) {
        while(my ($k, $v) = each( %{ $data->{'headers'} } )) {
            $out .= $k . ": " . $self->_sanitize_header($v) . "\n";
        }
    }
    $out .= "\n\n";
    if (defined($data->{'data'})) {
        $out .= $data->{'data'}
    }
    return $out;
}

sub _sanitize_header {
    my $self = shift;
    $_ = shift;
    s{(\n|\r)}{ }g;
    return $_;
}

1;
__END__

=head1 NAME

Blogolicious::Plugins::Spam::Bogofilter - spam detection based on bogofilter

=head1 DESCRIPTION
