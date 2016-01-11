# Copyright 2015 Navel-IT
# navel-scheduler is developed by Yoann Le Garff, Nicolas Boquet and Yann Le Bras under GNU GPL v3

#-> BEGIN

#-> initialization

package Navel::Scheduler::Mojolicious::Application 0.1;

use Carp 'croak';

use Mojo::Base 'Mojolicious';

use Navel::API::Swagger2::Scheduler;
use Navel::Utils 'blessed';

#-> methods

sub new {
    my ($class, $scheduler) = @_;

    croak('scheduler must be of Navel::Scheduler class') unless blessed($scheduler) eq 'Navel::Scheduler';

    my $self = $class->SUPER::new();

    $self->helper(
        scheduler => sub {
            $scheduler;
        }
    );

    $self->plugin('Navel::Mojolicious::Plugin::Logger',
        {
            logger => $self->scheduler()->{core}->{logger}
        }
    );

    $self->log()->level('debug')->unsubscribe('message')->on(
        message => sub {
            my ($log, $level, @lines) = @_;

            my $method = $level eq 'debug' ? 'debug' : 'info';

            $self->scheduler()->{core}->{logger}->$method('Mojolicious: ' . $self->scheduler()->{core}->{logger}->stepped_log(\@lines));
        }
    );

    $self;
}

sub startup {
    my $self = shift;

    local $@;

    $self->secrets(rand);

    $self->plugin('Navel::Mojolicious::Plugin::Swagger2::StdResponses');

    my $swagger_spec = Navel::API::Swagger2::Scheduler->new();

    $self->plugin(
        'Swagger2' => {
            swagger => $swagger_spec,
            route => $self->routes()->under()->to(
                cb => sub {
                    my $controller = shift;

                    my $userinfo = $controller->req()->url()->to_abs()->userinfo();

                    unless (defined $userinfo && $userinfo eq $self->scheduler()->{configuration}->{definition}->{webservices}->{credentials}->{login} . ':' . $self->scheduler()->{configuration}->{definition}->{webservices}->{credentials}->{password}) {
                        $controller->res()->headers()->www_authenticate('Basic');

                        $controller->render(
                            json => $controller->ok_ko(
                                {
                                    ok => [],
                                    ko => ['unauthorized: access is denied due to invalid credentials.']
                                }
                            ),
                            status => 401
                        );

                        return undef;
                    }

                    $controller->on(
                        finish => sub {
                            my $controller = shift;

                            my $exception = delete $controller->stash()->{exception};

                            if (defined $exception) {
                                my @exception_message = (
                                    'an exception has been raised for HTTP ' . $controller->req()->method() . ' on ' . $controller->req()->url()->to_string() . ': ',
                                    $exception
                                );

                                $controller->scheduler()->{core}->{logger}->error(
                                    $controller->scheduler()->{core}->{logger}->stepped_log(\@exception_message)
                                );

                                $controller->render(
                                    json => $controller->ok_ko(
                                        {
                                            ok => [],
                                            ko => @exception_message
                                        }
                                    ),
                                    status => 500
                                );

                                return undef;
                            }
                        }
                    );
                }
            )
        }
    );

    $self->defaults(
        swagger_spec => $swagger_spec->api_spec()
    );

    eval {
        $self->plugin('MojoX::JSON::XS');
    };

    $self->log()->debug($@) if $@;

    $self;
}

# sub AUTOLOAD {}

# sub DESTROY {}

1;

#-> END

__END__

=pod

=encoding utf8

=head1 NAME

Navel::Scheduler::Mojolicious::Application

=head1 AUTHOR

Yoann Le Garff, Nicolas Boquet and Yann Le Bras

=head1 LICENSE

GNU GPL v3

=cut

