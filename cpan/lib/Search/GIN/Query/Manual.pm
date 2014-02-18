use strict;
use warnings;
package Search::GIN::Query::Manual;
BEGIN {
  $Search::GIN::Query::Manual::VERSION = '0.08';
}
# ABSTRACT: Create manual GIN queries

use Moose;
use namespace::clean -except => 'meta';

with qw(
    Search::GIN::Query
    Search::GIN::Keys::Deep
);

has method => (
    isa => "Str",
    is  => "ro",
    predicate => "has_method",
);

has values => (
    isa => "Any",
    is  => "ro",
    required => 1,
);

has _processed => (
    is => "ro",
    lazy_build => 1,
);

has filter => (
    isa => "CodeRef|Str",
    is  => "ro",
);

sub _build__processed {
    my $self = shift;
    return [ $self->process_keys( $self->values ) ];
}

sub extract_values {
    my $self  = shift;
    my $EMPTY = q{};

    return (
        values => $self->_processed,
        method => $self->has_method ? $self->method : $EMPTY,
    );
}

sub consistent {
    my ( $self, $obj ) = @_;

    if ( my $filter = $self->filter ) {
        return $obj->$filter;
    } else {
        return 1;
    }
}

__PACKAGE__->meta->make_immutable;

1;



=pod

=head1 NAME

Search::GIN::Query::Manual - Create manual GIN queries

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use Search::GIN::Query::Manual;

    my $query = Search::GIN::Query::Manual->new(
        values => {
            name => 'Homer',
        }
    );

=head1 DESCRIPTION

Creates a manual GIN query that can be used to search records in a storage.

Unlike the stock GIN queries (L<Search::GIN::Query::Class>,
L<Search::GIN::Query::Attributes>), with this object you define your search
manually, allowing you to create any search you want.

=head1 METHODS/SUBROUTINES

=head2 new

Creates a new query.

=head1 ATTRIBUTES

=head2 values

The keys and values to build the query for.

=head1 AUTHOR

Yuval Kogman <nothingmuch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

