use strict;
use warnings;
package Search::GIN::Extract::Multiplex;
BEGIN {
  $Search::GIN::Extract::Multiplex::VERSION = '0.08';
}
# ABSTRACT:

use Moose;
use namespace::clean -except => 'meta';

with qw(Search::GIN::Extract);

has extractors => (
    isa => "ArrayRef[Search::GIN::Extract]",
    is  => "ro",
    required => 1,
);

sub extract_values {
    my ( $self, $obj, @args ) = @_;

    return map { $_->extract_values($obj, @args) } @{ $self->extractors };
}

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

Search::GIN::Extract::Multiplex - use Moose;

=head1 VERSION

version 0.08

=head1 SYNOPSIS

	use Search::GIN::Extract::Multiplex;

=head1 DESCRIPTION

=head1 AUTHOR

Yuval Kogman <nothingmuch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

