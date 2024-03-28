package AXbills::Sender::Mail;
=head1 NAME

  Send E-mail message

=cut


use strict;
use warnings FATAL => 'all';

use AXbills::Sender::Plugin;
use parent 'AXbills::Sender::Plugin';

use AXbills::Base qw(sendmail);

#**********************************************************
=head2 send_message($attr)

  Arguments:
    MESSAGE
    SUBJECT
    PRIORITY_ID
    TO_ADDRESS   - Email addess
    MAIL_TPL

  Returns:
    result_hash_ref

=cut
#**********************************************************
sub send_message {
  my $self = shift;
  my ($attr) = @_;

  unless ($attr->{TO_ADDRESS}) {
    print "No recipient address given \n" if ($self->{debug});
    return;
  };

  my $sender = $attr->{SENDER} || $self->{conf}->{ADMIN_MAIL} || 'axbills_admin';

  if ($attr->{MAIL_TPL}) {
    $attr->{MESSAGE} = $attr->{MAIL_TPL};
  }

  if ($attr->{TO_ADDRESS} =~ ',') {
    # Change all comma to semicolon ( for sendmail function )
    $attr->{TO_ADDRESS} = join(';', split(',\s?', $attr->{TO_ADDRESS}));
  }

  if ($attr->{ATTACHMENTS} && ref $attr->{ATTACHMENTS} eq 'ARRAY') {
    foreach my $attachment (@{$attr->{ATTACHMENTS}}) {
      my $content = $attachment->{CONTENT} || '';
      next if $content !~ /FILE:\s?(.*)/;

      my ($filename) = $content =~ /FILE: (.*)/;
      open(my $fh, '<', $filename) or next;
      {
        local $/;
        $content = <$fh>;
      }
      close($fh);
      $attachment->{CONTENT} = $content;
    }
  }

  my $sent = sendmail(
    $sender,
    $attr->{TO_ADDRESS},
    $attr->{SUBJECT},
    $attr->{MESSAGE},
    $self->{conf}->{MAIL_CHARSET} || 'utf-8',
    undef,
    {
      TRUSTED_FROM  => $self->{conf}->{SENDMAIL_TRUSTED_FROM},
      SENDMAIL_PATH => $self->{conf}->{FILE_SENDMAIL} || undef,
      TEST          => $self->{conf}->{MAIL_TEST} || undef,
      ATTACHMENTS   => $attr->{ATTACHMENTS} || undef,
      CONTENT_TYPE  => $attr->{CONTENT_TYPE} || '',
      MAIL_HEADER   => $attr->{MAIL_HEADER} || undef,
      QUITE         => $attr->{QUITE} || 0
    }
  );

  print "Sending E-mail\n Subject: $attr->{SUBJECT}\n $attr->{MESSAGE}\n" if ($self->{debug});
  $self->{status} = $sent || 0;
  $self->{STATUS} = $sent || 0;

  return $sent;
}

#**********************************************************
=head2 support_batch() - tells Sender, we can accept more than one recepient per call

=cut
#**********************************************************
sub support_batch {
  return 1;
}

1;
