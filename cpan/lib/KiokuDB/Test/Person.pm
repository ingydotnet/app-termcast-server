package KiokuDB::Test::Person;
BEGIN {
  $KiokuDB::Test::Person::AUTHORITY = 'cpan:NUFFIN';
}
{
  $KiokuDB::Test::Person::VERSION = '0.56';
}
use Moose;

use namespace::clean -except => 'meta';

has [qw(name age job binary)] => (
    isa => "Str",
    is  => "rw",
);

has so => (
    isa => "KiokuDB::Test::Person",
    is  => "rw",
    weak_ref => 1,
);

has [qw(parents kids friends)] => (
    isa => "ArrayRef[KiokuDB::Test::Person]",
    is  => "rw",
    default => sub { [] },
);

__PACKAGE__->meta->make_immutable;

__PACKAGE__

__END__

=pod

=head1 NAME

KiokuDB::Test::Person

=head1 VERSION

version 0.56

=head1 AUTHOR

Yuval Kogman <nothingmuch@woobling.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Yuval Kogman, Infinity Interactive.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
