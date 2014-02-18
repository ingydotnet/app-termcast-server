use strict;
use warnings;
package Search::GIN::Keys::Deep;
BEGIN {
  $Search::GIN::Keys::Deep::VERSION = '0.08';
}
# ABSTRACT:

use Moose::Role;
use namespace::clean -except => 'meta';

with qw(
    Search::GIN::Keys
    Search::GIN::Keys::Join
    Search::GIN::Keys::Expand
);

sub process_keys {
    my ( $self, @keys ) = @_;

    $self->join_keys( $self->expand_keys(@keys) );
}

1;



=pod

=head1 NAME

Search::GIN::Keys::Deep - use Moose::Role;

=head1 VERSION

version 0.08

=head1 SYNOPSIS

	with qw(Search::GIN::Keys::Deep);

=head1 DESCRIPTION

=head1 AUTHOR

Yuval Kogman <nothingmuch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

