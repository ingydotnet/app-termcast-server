use strict;
use warnings;
package Search::GIN::Driver::Pack::Length;
BEGIN {
  $Search::GIN::Driver::Pack::Length::VERSION = '0.08';
}
# ABSTRACT:

use Moose::Role;

use namespace::clean -except => [qw(meta)];

sub pack_length {
    my ( $self, @strings ) = @_;
    pack("(n/a*)*", @strings);
}

sub unpack_length {
    my ( $self, $string ) = @_;
    unpack("(n/a*)*", $string);
}

1;



=pod

=head1 NAME

Search::GIN::Driver::Pack::Length - use Moose::Role;

=head1 VERSION

version 0.08

=head1 SYNOPSIS

	use Search::GIN::Driver::PackLength;

=head1 DESCRIPTION

=head1 AUTHOR

Yuval Kogman <nothingmuch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

