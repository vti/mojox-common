Validator
---------

    my $validator = MojoX::Validator->new;

    # Fields
    $validator->field([qw/firstname lastname/])->required(1)->length(3, 20);
    $validator->field('phone')->required(1)->regexp(qr/^\d+$/);

    # Groups
    $validator->field([qw/password confirm_password/])->required(1);
    $validator->group('passwords' => [qw/password confirm_password/])->equal;

    # Conditions
    $validator->field('document');
    $validator->field('number');
    $validator->when('document')->regexp(qr/^1$/)
      ->then(sub { shift->field('number')->required });

    $validator->validate($values_hashref);
    my $errors_hashref = $validator->errors;
    my $validated_values_hashref = $validator->values;

Bot protection
______________

    $self->plugin('bot_protection');

Features

* Dummy field (bot fills out all the fields, including not visible one)
* Honeypot form (bot submits non visible to a normal user form)
* Cookies support check (bot has no cookies support)
* Flood protection (bot submits forms too fast)
* DDoS protection (bot submits the same forms many times)
* Referrer check (bot submits form with invalid referrer header)
* Identical fields check (bot submits form with identical fields)
