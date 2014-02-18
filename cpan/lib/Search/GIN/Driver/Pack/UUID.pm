use strict;
use warnings;
package Search::GIN::Driver::Pack::UUID;
BEGIN {
  $Search::GIN::Driver::Pack::UUID::VERSION = '0.08';
}
# ABSTRACT: UUID key packing

use Moose::Role;

use namespace::clean -except => [qw(meta)];

with qw(Search::GIN::Driver);

sub unpack_ids {
    my ( $self, $str ) = @_;
    unpack("(a16)*", $str);
}

sub pack_ids {
    my ( $self, @ids ) = @_;
    pack("(a16)*", @ids); # FIXME enforce size
}

1;



=pod

=head1 NAME

Search::GIN::Driver::Pack::UUID - UUID key packing

=head1 VERSION

version 0.08

=head1 SYNOPSIS

    use Search::GIN::Driver::PackUUID;

=head1 DESCRIPTION

=head1 AUTHOR

Yuval Kogman <nothingmuch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

