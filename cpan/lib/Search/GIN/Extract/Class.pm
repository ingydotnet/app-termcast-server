use strict;
use warnings;
package Search::GIN::Extract::Class;
BEGIN {
  $Search::GIN::Extract::Class::VERSION = '0.08';
}
# ABSTRACT:

use Moose;
use MRO::Compat;
use namespace::clean -except => 'meta';

with qw(
    Search::GIN::Extract
    Search::GIN::Keys::Deep
);

sub extract_values {
    my ( $self, $obj, @args ) = @_;

    my $class = ref $obj;

    my $isa = $class->mro::get_linear_isa();

    my $meta = Class::MOP::get_metaclass_by_name($class);
    my @roles = $meta && $meta->can("calculate_all_roles") ? ( map { $_->name } $meta->calculate_all_roles ) : ();

    return $self->process_keys({
        blessed => $class,
        class   => $isa,
        does    => \@roles,
    });
}

1;



=pod

=head1 NAME

Search::GIN::Extract::Class - use Moose;

=head1 VERSION

version 0.08

=head1 SYNOPSIS

	use Search::GIN::Extract::Class;

=head1 DESCRIPTION

=head1 AUTHOR

Yuval Kogman <nothingmuch@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2010 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

