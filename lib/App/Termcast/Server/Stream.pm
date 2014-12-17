package App::Termcast::Server::Stream;
use Moose;
use Reflex::Collection;
use Reflex::Stream;
use Try::Tiny;

use Scalar::Util 'weaken';
use KiokuX::User::Util qw(crypt_password);

use App::Termcast::Server::User;

# ABSTRACT: Reflex stream for handling broadcaster I/O

extends 'Reflex::Stream';

has stream_id => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has lines => (
    is => 'rw',
    isa => 'Num',
    default => 24,
);

has cols => (
    is => 'rw',
    isa => 'Num',
    default => 80,
);

has kiokudb => (
    is       => 'ro',
    isa      => 'KiokuDB',
    required => 1,
);

has user => (
    is       => 'rw',
    isa      => 'App::Termcast::Server::User',
);

# pass this down for reference
has handle_collection => (
    is     => 'ro',
    isa    => 'Reflex::Collection',
    required => 1,
);

has last_active => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { time() },
);

has unix => (
    is       => 'ro',
    isa      => 'App::Termcast::Server::UNIX',
    required => 1,
);

has interval => (
    is      => 'ro',
    isa     => 'Num',
    lazy    => 1,
    default => 0,
);

has _broadcast_ticker => (
    is        => 'rw',
    isa       => 'Maybe[Reflex::Interval]',
    predicate => 'on_interval',
);

has _broadcast_buffer => (
    is      => 'bare',
    isa     => 'Str',
    lazy    => 1,
    default => '',
);

has logging => (
    is      => 'rw',
    isa     => 'Bool',
    default => 0,
);

has log_path => (
    is      => 'ro',
    isa     => 'Str',
);

has log_handle => (
    is      => 'rw',
    isa     => 'IO::Handle',
    lazy    => 1,
    default => sub { IO::Handle->new },
);

=begin Pod::Coverage

property_data

_send_to_manager_handles

send_connection_notice

send_disconnection_notice

on_data

handle_metadata

handle_geometry

handle_auth

create_user

_disconnect

on_closed

on_error

shorten_buffer

fix_buffer_length

mark_active

=end Pod::Coverage

=cut

sub BUILD {
    my $self = shift;

    if ($self->logging) {
        open($self->log_handle, '>', $self->log_path)
            or die "Open log failed: $!";
        $self->log_handle->autoflush();
    }

    if ($self->interval) {
        my $wself = $self;
        weaken $wself;
        my $ticker = Reflex::Interval->new(
            auto_repeat => 1,
            interval    => $self->interval,
            on_tick   => sub {
                my $buf = $wself->{_broadcast_buffer};
                $wself->{_broadcast_buffer} = '';
                $self->_process_input($buf);
            },
        );

        $self->_broadcast_ticker($ticker);
    }
}

sub broadcast {
    my $self = shift;
    my $string = shift;

    $_->handle->syswrite($string)
        for $self->unix->sockets->get_objects;
}

sub property_data {
    my $self = shift;

    return {
            session_id  => $self->stream_id,
            user        => $self->user->id,
            socket      => $self->unix->file,
            geometry    => [$self->cols, $self->lines],
            last_active => $self->last_active,
    };
}

sub _send_to_manager_handles {
    my $self = shift;
    my $data = shift;

    if (not ref $data) {
        warn "$data is not a reference. Can't be encoded";
        return;
    }

    my @manager_handles = $self->handle_collection->get_objects;

    my $json = JSON::encode_json($data);
    foreach my $stream (@manager_handles) {
        $stream->handle->syswrite($json);
    }
}

sub send_connection_notice {
    my $self      = shift;

    my %response = (
        notice     => 'connect',
        connection => $self->property_data,
    );

    $self->_send_to_manager_handles(\%response);
}

sub send_disconnection_notice {
    my $self = shift;

    my %response = (
        notice     => 'disconnect',
        session_id => $self->stream_id,
    );

    $self->_send_to_manager_handles(\%response);
}

sub on_data {
    my ($self, $event) = @_;

    my $message = $event->octets;

    if ($self->logging) {
        $self->log_handle->syswrite($message);
    }

    if ($self->on_interval) {
        $self->{_broadcast_buffer} .= $message;
    }
    else {
        $self->_process_input($message);
    }

}

sub _process_input {
    my $self = shift;
    my ($input) = @_;

    if (!$self->user) {
        (my $auth_line, $input) = split /\n/, $input, 2;
        my $user = $self->handle_auth($auth_line) or do {
            $self->stopped();
            return;
        };

        $self->handle->syswrite("hello, ".$user->id."\n");
        $self->user($user);

        $self->send_connection_notice;
    }

    my $cleared = 0;
    if ($input =~ s/\e]499;(.*?)\x07//) {
        my $metadata;
        if (
            $1 && try { $metadata = JSON::decode_json( $1 ) }
               && ref($metadata)
               && ref($metadata) eq 'HASH'
        ) {
            $self->handle_metadata($metadata);

            my %data = (
                notice     => 'metadata',
                session_id => $self->stream_id,
                metadata   => $metadata,
            );

            $self->_send_to_manager_handles(\%data);
        }
        $cleared = 1;
    }

    $self->broadcast($input);

    $self->unix->add_to_buffer($input);
    $self->shorten_buffer();
    $self->mark_active();
}

sub handle_metadata {
    my $self     = shift;
    my $metadata = shift;

    return unless ref($metadata) eq 'HASH';

    if ($metadata->{geometry}) {
        $self->handle_geometry($metadata);
    }
}

sub handle_geometry {
    my $self     = shift;
    my $metadata = shift;

    my ($cols, $lines) = @{ $metadata->{geometry} };

    $self->cols($cols);
    $self->lines($lines);
}

sub handle_auth {
    my $self   = shift;
    my $line   = shift;

    my ($type, $user, $pass) = split(' ', $line, 3);

    return unless $type eq 'hello';

    my $user_object;
    {
        my $scope = $self->kiokudb->new_scope;
        $user_object = $self->kiokudb->lookup($user)
                    || $self->create_user($user, $pass);
    }

    if ($user_object->check_password($pass)) {
        return $user_object;
    }
    else {
        return undef;
    }
}

sub create_user {
    my $self = shift;
    my $user = shift;
    my $pass = shift;

    my $user_object;

    $user_object = App::Termcast::Server::User->new(
        id       => $user,
        password => crypt_password($pass),
    );

    {
        my $s = $self->kiokudb->new_scope;
        $self->kiokudb->store($user => $user_object);
    }

    return $user_object;
}

sub _disconnect {
    my ($self) = @_;

    $self->log_handle->close if $self->logging;
    $self->send_disconnection_notice();

    $_->stopped() for $self->unix->sockets->get_objects;
}
sub on_closed {
    my ($self) = @_;
    $self->_disconnect();
    $self->stopped();
}

sub on_error {
    my ($self) = @_;
    $self->_disconnect();
}

sub shorten_buffer {
    my $self = shift;

    $self->fix_buffer_length();
    $self->unix->{buffer} =~ s/.+\e\[2J//s;
}

sub fix_buffer_length {
    my $self = shift;
    my $len = $self->unix->buffer_length;
    if ($len > 51_200) {
        substr($self->unix->{buffer}, 0, $len-51_200) = '';
    }
}

sub mark_active { shift->last_active( time() ); }

__PACKAGE__->meta->make_immutable;
no Moose;

1;
