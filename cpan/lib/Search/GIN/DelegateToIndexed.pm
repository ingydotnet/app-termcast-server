use strict;
use warnings;
package Search::GIN::DelegateToIndexed;
BEGIN {
  $Search::GIN::DelegateToIndexed::VERSION = '0.08';
}
# ABSTRACT:

use Moose::Role;

use namespace::clean -except => 'meta';

with qw(Search::GIN::Core);

requires "ids_to_objects";

sub extract_values {
    my ( $self, $obj, @args ) = @_;
    $obj->gin_extract_values($self, @args);
}

sub compare_values {
    my ( $self, $obj, @args ) = @_;
    $obj->gin_compare_values($self, @args);
}

sub objects_to_ids {
    my ( $self, @objs ) = @_;
    map { $_->gin_id } @objs;
}

1;



=pod

=head1 NAME

Search::GIN::DelegateToIndexed - use Moose::Role;

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use Search::GIN::DelegateToIndexed;

=head1 DESCRIPTION

=head1 AUTHOR

Yuval Kogman <nothingmuch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

