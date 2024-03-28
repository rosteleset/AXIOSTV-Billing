package Cablecat::Trace;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Cablecat::Trace

=head2 SYNOPSIS

  This package aggregates function to trace paths for cables

=cut

use AXbills::Base qw/in_array _bp/;

use Cablecat;
our Cablecat $Cablecat;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    
  Returns:
    object
    
=cut
#**********************************************************
sub new {
  my $class = shift;

  my ($db, $admin, $CONF) = @_;

  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };

  bless($self, $class);

  $Cablecat //= Cablecat->new($db, $admin, $CONF);

  return $self;
}

#**********************************************************
=head2 find_equipment_for_user($uid) - returns equipment user is connected to

  Arguments:
    $uid
    
  Returns:
    \@equipment_id
  
=cut
#**********************************************************
sub find_equipment_for_user {
  my ($self, $uid) = @_;

  my $services_list = $self->get_user_services($uid);
  my @nas_ids = map {$_->{nas_id}} @{$services_list};
  return 0 unless (@nas_ids);

  require Equipment;
  my $Equipment = Equipment->new(@{$self}{qw/db admin conf/});
  my $nases_list = $Equipment->_list({
    NAS_ID    => join(';', @nas_ids),
    NAS_NAME  => '_SHOW',
    COLS_NAME => 1
  });

  return $nases_list;
}


#**********************************************************
=head2 get_uplink_chain_for($equipment_id) - returns uplink connected nases

  Arguments:
    $equipment_id -
    
  Returns:
    $fiber_id
    
=cut
#**********************************************************
sub get_uplink_chain_for {
  my ($self, $equipment_id) = @_;

  require Equipment;
  my $Equipment = Equipment->new(@{$self}{qw/db admin conf/});

  my @uplink_chain = ();
  my %unique_nas_ids_hash = ();

  my $add_uplinks_for;
  $add_uplinks_for = sub {
    my ($nas_id) = @_;

    $unique_nas_ids_hash{$nas_id} = 1;

    my $next_uplinks = $Equipment->port_list({
      NAS_ID      => $nas_id,
      UPLINK      => '!',
      PORT        => '_SHOW',
      _SKIP_TOTAL => 1,
      COLS_NAME   => 1
    });

    # Adding last element as a top of the chain
    if (!$next_uplinks || (ref $next_uplinks eq 'ARRAY' && !scalar(@$next_uplinks))) {
      push(@uplink_chain, { nas_id => $nas_id });
    }

    foreach my $uplink (@{$next_uplinks}) {
      push(@uplink_chain, $uplink);

      # Skip loops
      next if (exists $unique_nas_ids_hash{$uplink->{uplink}});

      # Recursive
      $add_uplinks_for->($uplink->{uplink});
    }
  };

  $add_uplinks_for->($equipment_id);

  # Now should extend info with nas_name (for select)
  my @unique_nas_ids = sort keys %unique_nas_ids_hash;

  my $nases_list = $Equipment->_list({
    NAS_ID    => join(';', @unique_nas_ids),
    NAS_NAME  => '_SHOW',
    COLS_NAME => 1
  });
  my %nases_by_id = map {$_->{nas_id} => $_} @{$nases_list};

  # Map will save order
  my @full_info_uplink_chain = map {
    $_->{nas_name} = $nases_by_id{$_->{nas_id} }->{nas_name};
    $_;
  } @uplink_chain;

  # Removing first element
  shift @full_info_uplink_chain;

  return \@full_info_uplink_chain;
}


#**********************************************************
=head2 get_commutation_for_equipment($equipment_id, $port, $attr)

  Arguments:
    $equipment_id -
    $port         - show only commutations with given equipment port (for crosses)
    $attr         - hash_ref
      WITH_TYPE - returns type for commutation_present { COMMUTATION_ID => number, TYPE => ('CROSS' or 'EQUIPMENT') }
    
  Returns:
    $commutation_ids arr_ref or 0
    
=cut
#**********************************************************
sub get_commutation_for_equipment {
  my ($self, $equipment_id, $port, $attr) = @_;
  return 0 unless ($equipment_id);

  $attr //= {};

  my $equipment_commutations_list = $Cablecat->commutation_equipment_list({
    NAS_ID         => $equipment_id,
    COMMUTATION_ID => '_SHOW',
    COLS_NAME      => 1,
    _SKIP_TOTAL    => 1,
  });

  if ($Cablecat->{errno}) {
    $self->_mimicre_error($Cablecat);
    return 0
  };

  my @result = ();
  my $type = '';

  if (scalar(@{$equipment_commutations_list})) {
    $type = 'EQUIPMENT';
    @result = map {{
      commutation_id => $_->{commutation_id},
        id           => $_->{nas_id},
        port         => $port || q{},
    }} @{$equipment_commutations_list};
  }
  else {
    # Equipment also can be presented as cross port
    my $cross_links = $Cablecat->cross_links_list({
      CROSS_ID    => '_SHOW',
      CROSS_PORT  => '_SHOW',
      LINK_TYPE   => '1',
      LINK_VALUE  => "$equipment_id#@#" . ($port || '*'),
      _SKIP_TOTAL => 1,

    });
    if ($Cablecat->{errno}) {
      $self->_mimicre_error($Cablecat);
      return 0
    };

    # There should be only one link for this cross port
    if (!$cross_links || ref $cross_links ne 'ARRAY' || !scalar(@$cross_links)) {
      $self->_raise_error(2200, "Equipment is not present on commutation");
      return 0;
    }
    elsif ($port && scalar @$cross_links > 1) {
      $self->_raise_error(2213, "Equipment port is linked to more than one cross port");
      return 0;
    }

    # So we are in situation when there's only one cross port
    my $cross_nas_link = $cross_links->[0];

    if ($cross_links && ref $cross_links eq 'ARRAY') {
      my $cross_commutation_list = $Cablecat->commutation_crosses_list({
        CROSS_ID       => $cross_nas_link->{cross_id},
        PORT           => $cross_nas_link->{cross_port},
        COMMUTATION_ID => '_SHOW',
        _SKIP_TOTAL    => 1,
      });
      if ($Cablecat->{errno}) {
        $self->_mimicre_error($Cablecat);
        return 0;
      }
      elsif (!$cross_commutation_list || ref $cross_commutation_list ne 'ARRAY') {
        $self->_raise_error(2213, "Error while getting commutation for equipment using cross port");
        return 0;
      }
      elsif (!scalar @$cross_commutation_list) {
        $self->_raise_error(2214, "Cross port to which equipment port is linked no present on commutation");
        return 0;
      }
      elsif (scalar @$cross_commutation_list > 1) {
        $self->_raise_error(2215, "Cross port to which equipment port is linked is present on more than one commutation");
        return 0;
      }

      # So we are in situation when there's only one cross port link
      my $cross_port_commutation = $cross_commutation_list->[0];

      $type = 'CROSS';
      @result = ({
        commutation_id => $cross_port_commutation->{commutation_id},
        id             => $cross_nas_link->{cross_id},
        port           => $cross_nas_link->{cross_port},
      });
    }
  }

  my @commutation_ids = map {($attr->{WITH_TYPE})
    ? { COMMUTATION_ID => $_->{commutation_id}, TYPE => $type, ID => $_->{id}, FIBER_NUM => $_->{port} }
    : $_->{commutation_id}
  } @result;

  return \@commutation_ids;
}

#**********************************************************
=head2 get_commutation_for_user($uid) - find commutation for user

  Arguments:
    $uid -
    $attr -
      RETURN_LINK
    
  Returns:
    number or hash (if $attr->{RETURN_LINK})
  
=cut
#**********************************************************
sub get_commutation_for_user {
  my ($self, $uid, $service_id, $attr) = @_;

  my $onu_list = $Cablecat->commutation_onu_list({
    UID        => $uid,
    SERVICE_ID => $service_id,
    ID         => '_SHOW',
    COLS_NAME  => 1
  });

  return 0 if ($Cablecat->{TOTAL} <= 0);

  return $self->get_commutation_for_element({
    TYPE      => 'ONU',
    ID        => $onu_list->[0]->{id},
    FIBER_NUM => 1
  }, $attr);
}

#**********************************************************
=head2 get_commutation_for_element($element_hash, $attr) -

  Arguments:
    $element_hash - hash_ref
      TYPE
      ID
      FIBER_NUM
    $attr - hash_ref
      ALL_LINKS   - return all links (arr_ref)
      RETURN_LINK - returns single full link_info (hash_ref)
    
  Returns:
    number or hash_ref or arr_ref
    
=cut
#**********************************************************
sub get_commutation_for_element {
  my ($self, $element_hash, $attr) = @_;

  return 0 if !$element_hash->{TYPE};

  if ($element_hash->{TYPE} eq 'EQUIPMENT') {
    # Can be present as cross
    my $equipment_cross = $self->get_commutation_for_equipment($element_hash->{ID}, $element_hash->{FIBER_NUM},
      { WITH_TYPE => 1 });
    #TODO: when got cross link, replace $element_hash
  }

  my $cable_links = $Cablecat->links_list({
    FOR_ELEMENT_AND_FIBER => {
      ELEMENT_TYPE => $element_hash->{TYPE},
      ELEMENT_ID   => $element_hash->{ID},
      FIBER_NUM    => $element_hash->{FIBER_NUM}
    },
    COMMUTATION_ID        => '_SHOW',
    SHOW_ALL_COLUMNS      => ($attr->{RETURN_LINK} || 0),
    PAGE_ROWS             => 1000
  });

  if ($Cablecat->{errno}) {
    $self->_mimicre_error($Cablecat);
    return 0;
  }
  elsif (!$cable_links || (ref $cable_links ne 'ARRAY' || !scalar(@{$cable_links}))) {
    $self->{errno} = 2210;
    $self->{errstr} = "User is not present on commutation";
    return 0;
  }

  my $cable_link = ($attr->{ALL_LINKS} ? $cable_links : $cable_links->[0]);

  return $attr->{ALL_LINKS} ? $cable_links : $attr->{RETURN_LINK} ? $cable_link : $cable_link->[0]{commutation_id};
}

#**********************************************************
=head2 get_user_nas_port_services($uid) -

  Arguments:
    $uid - user ID
    
  Returns:
    list - [ { SERVICE_ID => number, NAS_ID => number,  PORT => string } ]
  
=cut
#**********************************************************
sub get_user_nas_port_services {
  my ($self, $uid) = @_;

  my ($search_list, $module_name) = $self->get_user_services($uid, {
    NAS_NAME           => '_SHOW',
    RETURN_WITH_MODULE => 1
  });

  return 0 if $self->{errno};

  $module_name ||= '';
  if (!$search_list || !ref $search_list eq 'ARRAY' || !scalar(@{$search_list})) {
    $self->_raise_error(2211, "User is not linked to any equipment port ($module_name)");
    return 0;
  }

  my @formatted_services = map {{
    MODULE     => $module_name,
    SERVICE_ID => $_->{id},
    NAS_ID     => $_->{nas_id},
    NAS_NAME   => $_->{nas_name},
    PORT       => $_->{port}
  }} @{$search_list};

  # Checks are provided upper, but just to be sure
  if (!@formatted_services) {
    $self->_raise_error(2211, "User is not linked to equipment");
    return 0;
  }

  return \@formatted_services;
}

#**********************************************************
=head2 get_nas_port_for_service($uid, $service_id) - returns info about service

  Arguments:
    $uid
    $service_id -
    
  Returns:
    hash_ref
    
=cut
#**********************************************************
sub get_nas_port_for_service {
  my ($self, $uid, $service_id) = @_;

  my ($service_list) = $self->get_user_services($uid, { SERVICE_ID => $service_id, NAS_NAME => '_SHOW' });

  if (!$service_list || ref $service_list ne 'ARRAY' || !scalar(@$service_list)) {
    $self->_raise_error(2212, "Can't find service info");
    return 0
  }

  return $service_list->[0];
}

#**********************************************************
=head2 resolve_commutation_path($current_commutation_id, $element_type, $element_id, $fiber_num)

  Arguments:
    $current_commutation_id
    $element_type
    $element_id
    $fiber_num -
    
  Returns:
   hash_ref
     START_COMMUTATION_ID
     ENDS                 - Is this end of links chain?
     PATH                 - array_ref (contains links)
  
=cut
#**********************************************************
sub resolve_commutation_path {
  my ($self, $commutation_hash, $element_type, $element_id, $fiber_num) = @_;

  my $commutation_id = $commutation_hash->{commutation_id};

  # Find all links on this commutation
  my $commutation_links_list = [];
  $commutation_links_list = $Cablecat->links_list({
    COMMUTATION_ID => $commutation_id,
    ELEMENT_1_TYPE => '_SHOW',
    ELEMENT_1_ID   => '_SHOW',
    FIBER_NUM_1    => '_SHOW',
    ELEMENT_2_TYPE => '_SHOW',
    ELEMENT_2_ID   => '_SHOW',
    FIBER_NUM_2    => '_SHOW',
  });

  if ($Cablecat->{errno}) {
    $self->_mimicre_error($Cablecat);
    return 0;
  }

  # Build reference map
  my %link_for_fiber = ();
  foreach my $link (@{$commutation_links_list}) {
    $link_for_fiber{$link->{element_1_type} . '_' . $link->{element_1_id} . '_' . $link->{fiber_num_1}} = $link;
    $link_for_fiber{$link->{element_2_type} . '_' . $link->{element_2_id} . '_' . $link->{fiber_num_2}} = $link;
  }

  my @full_path = ();
  # Add first fiber
  my @next_link_array = ($element_type, $element_id, $fiber_num);
  my $start_link = $link_for_fiber{join('_', @next_link_array)};

  _bp('', "Not found " . join('_', @next_link_array)) if !$start_link;

  push(@full_path, _get_this_element_for_link($start_link, @next_link_array));

  # Should find exit fiber
  my $exit_fiber = undef;
  while (!defined $exit_fiber) {
    # Go on chain while has next element.
    my $current_fiber_text = join('_', @next_link_array);
    my $next_link = $link_for_fiber{$current_fiber_text};

    my $other_fiber = _get_another_element_for_link($next_link, @next_link_array);
    if (!$other_fiber->{element_type}) {
      return { START_COMMUTATION_ID => $commutation_id, ENDS => 0, PATH => \@full_path };
    }

    @next_link_array = (@{$other_fiber}{qw/element_type element_id fiber_num/});
    push(@full_path, $other_fiber);

    # Cable means this is exit to another commutation
    if ($other_fiber->{element_type} eq 'CABLE') {
      return { START_COMMUTATION_ID => $commutation_id, ENDS => 0, PATH => \@full_path };
    }
    # Equipment means this is dead end
    elsif ($other_fiber->{element_type} eq 'EQUIPMENT') {
      return { START_COMMUTATION_ID => $commutation_id, ENDS => 1, PATH => \@full_path };
    }
    # Splitter means we should proceed at another end of splitter
    elsif ($other_fiber->{element_type} eq 'SPLITTER') {
      # Get info about this splitter
      my $splitter_info = $Cablecat->splitters_info($other_fiber->{element_id});

      if ($other_fiber->{fiber_num} <= $splitter_info->{FIBERS_IN}) {
        $self->{errno} = 2209;
        $self->{errstr} = "Can't resolve connecters OUT to IN on commutation $commutation_id ( $other_fiber->{fiber_num})";
        return { START_COMMUTATION_ID => $commutation_id, ENDS => 1, PATH => \@full_path };
      }

      my $splitter_out_fiber = int($other_fiber->{fiber_num} * (($splitter_info->{FIBERS_IN} / $splitter_info->{FIBERS_OUT}) || 1)) || 1;

      if (!$splitter_out_fiber) {
        $self->{errno} = 2208;
        $self->{errstr} = "Can't resolve splitter type $splitter_info->{TYPE_ID} $splitter_info->{FIBERS_IN}/$splitter_info->{FIBERS_OUT}";
        return 0;
      }

      @next_link_array = ('SPLITTER', $other_fiber->{element_id}, $splitter_out_fiber);
    }
    elsif ($other_fiber->{element_type} eq 'CROSS') {
      # Cross is dead end
      return { START_COMMUTATION_ID => $commutation_id, ENDS => 1, PATH => \@full_path };
    }
    elsif ($other_fiber->{element_type} eq 'ONU') {
      # ONU is dead end
      return { START_COMMUTATION_ID => $commutation_id, ENDS => 1, PATH => \@full_path };
    }
  }

  return 0;
}

#**********************************************************
=head2 get_path_beetween_nases($nas_id1, $nas_id2) - returns fibers and points for links

  Arguments:
    $nas_id1 -
    $nas_id2 -
    
  Returns:
  
  
=cut
#**********************************************************
sub get_path_beetween_nases {
  my ($self, $nas_id1, $nas_id2) = @_;

  my $first_commutation_list = $self->get_commutation_for_equipment($nas_id1);
  my $second_commutation_list = $self->get_commutation_for_equipment($nas_id2);

  if (!$first_commutation_list || !$second_commutation_list) {
    $self->{errno} = 2200;
    $self->{errstr} = 'NAS_ID' . (!$first_commutation_list ? 1 : 2)
      . ' ' . (!$first_commutation_list ? $nas_id1 : $nas_id2)
      . ' is not present on any commutation';
    return 0
  };

  my $first_commutation_hash = -1;

  if (scalar(@{$first_commutation_list}) > 1 || scalar(@{$second_commutation_list}) > 1) {
    # This should not happen for now
    # Single equipment on single commutation
    $self->{errno} = 2201;
    $self->{errstr} = "Single equipment should be present on single commutation";
    return 0;
  }
  else {
    $first_commutation_hash = $first_commutation_hash->[0];
  }

  # Get equipment's uplink
  require Equipment;
  my $Equipment = Equipment->new(@{$self}{qw/db admin conf/});

  my $uplinks = $Equipment->port_list({
    NAS_ID      => $nas_id1,
    UPLINK      => '!',
    PORT        => '_SHOW',
    _SKIP_TOTAL => 1,
    COLS_NAME   => 1
  });
  if ($Equipment->{errno} || !$Equipment->{TOTAL}) {
    $self->{errno} = 2202;
    $self->{errstr} = "Can't get equipment's uplink for NAS_ID $nas_id1";
    return 0;
  }

  my $uplink = $uplinks->[0];

  # Get Cable/Element this equipment uplink fiber is linked to

  # Path starts from equipment port
  my @full_path = ();
  my $commutation_resolve = $self->resolve_commutation_path(
    $first_commutation_hash, 'EQUIPMENT', $nas_id1, $uplink->{port}
  );

  my $limit = 300;
  my $limit_counter = 0;
  while (!$commutation_resolve->{ENDS} && ++$limit_counter < $limit) {

    my $last_index = scalar(@{$commutation_resolve->{PATH}}) - 1;
    # Find another commutation
    my $exit_element_hash = $commutation_resolve->{PATH}->[$last_index];
    if (!$exit_element_hash) {
      _bp('Resolved path', $commutation_resolve);
      $self->{errno} = 2203;
      $self->{errstr} = 'ENDS but No PATH given';
      return 0;
    }

    my @exit_el_array = @{$exit_element_hash}{qw/element_type element_id fiber_num/};

    my $other_commutations_for_element = $Cablecat->links_list({
      COMMUTATION_ID        => "!$exit_element_hash->{commutation_id}",
      _SKIP_TOTAL           => 1,
      FOR_ELEMENT_AND_FIBER => {
        ELEMENT_TYPE => $exit_element_hash->{element_type},
        ELEMENT_ID   => $exit_element_hash->{element_id},
        FIBER_NUM    => $exit_element_hash->{fiber_num},
      },
    });

    # Check dead end
    if (!$other_commutations_for_element || ref($other_commutations_for_element) ne 'ARRAY') {
      $self->{errno} = 2204;
      $self->{errstr} = 'Wrong list for other end commutation';
      return 0;
    }
    elsif (!scalar(@{$other_commutations_for_element})) {
      $self->{errno} = 2205;
      $self->{errstr} = "Chain seems to be broken. Commutation #$exit_element_hash->{commutation_id}" .
        " Last element fiber : " . join(' ', @exit_el_array);
      return 0;
    }
    # Check is present on many commutations
    elsif (scalar(@{$other_commutations_for_element}) > 1) {
      $self->{errno} = 2206;
      $self->{errstr} = "Multiple links on other commutations for element : " . join(' ', @exit_el_array);
      _bp('', $other_commutations_for_element) if ($self->{debug});
      return 0;
    }
    else {

      # Proceed with this fiber as start
      push(@full_path, @{$commutation_resolve->{PATH}});
      $commutation_resolve = $self->resolve_commutation_path(
        $other_commutations_for_element->[0], @exit_el_array
      );
    }

    return \@full_path if $self->{errno};

  }

  if ($commutation_resolve->{PATH} && ref $commutation_resolve->{PATH} eq 'ARRAY') {
    push(@full_path, @{$commutation_resolve->{PATH}});
  }

  return \@full_path;
}
#**********************************************************
=head2 get_path_beetween($element_1, $element_2) - returns fibers and points for links

  Arguments:
    $element1 - hash_ref
      TYPE      - string
      ID        - id
      FIBER_NUM - num
    $element2 - hash_ref
      TYPE      - string
      ID        - id
      FIBER_NUM - num
    
  Returns:
    arr_ref
  
=cut
#**********************************************************
sub get_path_beetween {
  my ($self, $element1, $element2) = @_;

  my $first_commutation_list = $self->get_commutation_for_element($element1, { ALL_LINKS => 1 });
  my $second_commutation_list = $self->get_commutation_for_element($element2, { ALL_LINKS => 1 });
  my $first_commutation = -1;

  if (!$first_commutation_list || !$second_commutation_list) {
    $self->{errno} = 2200;
    my $missing_element = (!$first_commutation_list ? $element1 : $element2);
    my ($type, $id, $fiber) = @{$missing_element}{qw/TYPE ID FIBER_NUM/};
    $self->{errstr} = ::_translate('$lang{' . $type . '} #' . ($id || '0') . '</br>$lang{PORT}: ' . $fiber
      . ' $lang{IS_NOT_PRESENT_ON_ANY_COMMUTATION}');
    return 0;
  };

  if (scalar(@{$first_commutation_list}) > 1 || scalar(@{$second_commutation_list}) > 1) {
    $self->{errno} = 2201;
    $self->{errstr} = "Single element should be present on single commutation, check Broken links";
    return 0;
  }
  else {
    $first_commutation = $first_commutation_list->[0];
  }

  # Path starts from equipment port
  my @full_path = ();
  my $commutation_resolve = $self->resolve_commutation_path(
    $first_commutation, $element1->{TYPE}, $element1->{ID}, $element1->{FIBER_NUM}
  );
  return 0 if ($self->{errno});

  my $limit = 1000;
  my $limit_counter = 0;
  while (!$commutation_resolve->{ENDS} && ++$limit_counter < $limit) {

    my $last_index = scalar(@{$commutation_resolve->{PATH}}) - 1;
    # Find another commutation
    my $exit_element_hash = $commutation_resolve->{PATH}->[$last_index];
    if (!$exit_element_hash) {
      _bp('Resolved path', $commutation_resolve);
      $self->{errno} = 2203;
      $self->{errstr} = 'ENDS but No PATH given';
      return 0;
    }

    my @exit_el_array = @{$exit_element_hash}{qw/element_type element_id fiber_num/};

    my $other_commutations_for_element = $Cablecat->links_list({
      COMMUTATION_ID        => "!$exit_element_hash->{commutation_id}",
      _SKIP_TOTAL           => 1,
      FOR_ELEMENT_AND_FIBER => {
        ELEMENT_TYPE => $exit_element_hash->{element_type},
        ELEMENT_ID   => $exit_element_hash->{element_id},
        FIBER_NUM    => $exit_element_hash->{fiber_num},
      },
    });

    # Check dead end
    if (!$other_commutations_for_element || ref($other_commutations_for_element) ne 'ARRAY') {
      $self->{errno} = 2204;
      $self->{errstr} = 'Wrong list for other end commutation';
      return 0;
    }
    elsif (!scalar(@{$other_commutations_for_element})) {
      my $err_str = '$lang{CHAIN_SEEMS_TO_BE_BROKEN} ';
      if ($exit_el_array[0] ne 'CABLE') {
        $err_str .= ' $lang{COMMUTATION} ' . "#$exit_element_hash->{commutation_id}</br>" . '$lang{LAST_ELEMENT}: $lang{'
          . $exit_el_array[0] . '}#' . $exit_el_array[1];
      }
      else {
        $err_str .= '$lang{AFTER_COMMUTATION} ' . "#$exit_element_hash->{commutation_id}";
      }

      push(@full_path, @{$commutation_resolve->{PATH}});
      push(@full_path, ({
        element_type   => 'ERROR',
        ERROR          => $exit_element_hash->{commutation_id},
        commutation_id => $exit_element_hash->{commutation_id},
        fiber_num      => $err_str,
        LAST_CONNECT   => \@exit_el_array
      }));
      return \@full_path;
    }
    # Check is present on many commutations
    elsif (scalar(@{$other_commutations_for_element}) > 1) {
      $self->{errno} = 2206;
      $self->{errstr} = "Multiple links on other commutations for element : " . join(' ', @exit_el_array);
      return 0;
    }
    else {
      # Proceed with this fiber as start
      push(@full_path, @{$commutation_resolve->{PATH}});
      $commutation_resolve = $self->resolve_commutation_path(
        $other_commutations_for_element->[0], @exit_el_array
      );
    }

    return \@full_path if $self->{errno};
  }

  if ($commutation_resolve->{PATH} && ref $commutation_resolve->{PATH} eq 'ARRAY') {
    push(@full_path, @{$commutation_resolve->{PATH}});
  }

  return \@full_path;
}

#**********************************************************
=head2 _get_another_element_for_link($link, $this_el_type, $this_el_id, $this_el_fiber)

  Arguments:
    $link          - link DB row
    $this_el_type  -
    $this_el_id    -
    $this_el_fiber -
  
=cut
#**********************************************************
sub _get_another_element_for_link {
  my ($link, $this_el_type, $this_el_id, $this_el_fiber) = @_;

  return () if !$link;

  my $is_first = (($link->{element_1_type} eq $this_el_type && $link->{element_1_id} eq $this_el_id) ||
    ($link->{element_1_type} eq $this_el_type && $link->{element_1_id} eq $this_el_id && $link->{fiber_num_1} != $this_el_fiber));

  my $point_id = 0;
  my $reverse = 0;
  my $type = (!$is_first) ? $link->{element_1_type} : $link->{element_2_type};
  my $id = (!$is_first) ? $link->{element_1_id} : $link->{element_2_id};
  if ($type eq 'CABLE') {
    my $cable = $Cablecat->cables_info($id);

    $point_id = $cable->{POINT_ID};
    $reverse = 1 if $is_first;
  }

  return {
    link_id        => $link->{id},
    commutation_id => $link->{commutation_id},
    element_type   => $type,
    element_id     => $id,
    fiber_num      => (!$is_first) ? $link->{fiber_num_1} : $link->{fiber_num_2},
    point_id       => $point_id,
    reverse        => $reverse
  };
}

#**********************************************************
=head2 _get_this_element_for_link($link, $this_el_type, $this_el_id, $this_el_fiber)

  Arguments:
    $link          - link DB row
    $this_el_type  -
    $this_el_id    -
    $this_el_fiber -
  
=cut
#**********************************************************
sub _get_this_element_for_link {
  my ($link, $this_el_type, $this_el_id, $this_el_fiber) = @_;

  my $is_first = (($link->{element_1_type} eq $this_el_type && $link->{element_1_id} eq $this_el_id) ||
    ($link->{element_1_type} eq $this_el_type && $link->{element_1_id} eq $this_el_id && $link->{fiber_num_1} != $this_el_fiber));

  my $point_id = 0;
  my $reverse = 0;
  my $type = ($is_first) ? $link->{element_1_type} : $link->{element_2_type};
  my $id = ($is_first) ? $link->{element_1_id} : $link->{element_2_id};
  if ($type eq 'CABLE') {
    my $cable = $Cablecat->cables_info($id);

    $point_id = $cable->{POINT_ID};
    $reverse = 1 if ($is_first);
  }

  return {
    link_id        => $link->{id},
    commutation_id => $link->{commutation_id},
    element_type   => $type,
    element_id     => $id,
    fiber_num      => ($is_first) ? $link->{fiber_num_1} : $link->{fiber_num_2},
    point_id       => $point_id,
    reverse        => $reverse,
  };
}

#**********************************************************
=head2 _raise_error($error_code, $error_text) - sets error flag

  Arguments:
    $error_code
    $error_text
    
  Returns:
    $self
    
=cut
#**********************************************************
sub _raise_error {
  my ($self, $error_code, $error_text) = @_;
  $self->{errno} = $error_code;
  $self->{errstr} = $error_text;
  return $self;
}

#**********************************************************
=head2 _mimicre_error($module_object) - copies errno and errstr

  Arguments:
     $module_object - object with error
    
  Returns:
    1
    
=cut
#**********************************************************
sub _mimicre_error {
  my ($self, $module_object) = @_;

  return 0 unless $module_object->{errno};

  $self->{errno} = $module_object->{errno};
  $self->{errstr} = $module_object->{errstr};

  if ($module_object->{sql_errno}) {
    $self->{sql_errno} = $module_object->{sql_errno};
    $self->{sql_errstr} = $module_object->{sql_errstr};
    $self->{sql_query} = $module_object->{sql_query};
  }

  return 1;
}

#**********************************************************
=head2 get_user_services($uid, $attr) - searches for user equipment link services

  Arguments:
    $uid -
    $attr -
      SERVICE_ID
      NAS_NAME
      
  Returns:
    arr_ref in scalar context
   ( arr_ref, string ) in list context
  
=cut
#**********************************************************
sub get_user_services {
  my ($self, $uid, $attr) = @_;

  my @services_list = ();
  if (in_array('Internet', \@main::MODULES)) {
    require Internet;

    my $Internet = Internet->new(@{$self}{qw/db admin conf/});
    my $services_list = $Internet->user_list({
      UID       => $uid,
      ID        => ($attr->{SERVICE_ID} || '_SHOW'),
      NAS_ID    => '_SHOW',
      GROUP_BY  => 'internet.id',
      PORT      => '_SHOW',
      %{$attr // {}},
      PAGE_ROWS => 1000,
      COLS_NAME => 1,
    });

    if ($Internet->{errno}) {
      $self->_mimicre_error($Internet);
      return 0;
    }
    if ($attr->{NAS_NAME} && $attr->{NAS_NAME} eq '_SHOW') {
      # Should get names for nases
      require Nas;
      my $Nas = Nas->new(@{$self}{qw/db conf admin/});
      $Nas->list({
        NAS_ID    => join(';', map {$_->{nas_id}} @$services_list),
        LIST2HASH => 'nas_id,nas_name'
      });
      if ($Nas->{errno}) {
        $self->_mimicre_error($Nas);
        return 0;
      }
      if ($services_list && ref $services_list eq 'ARRAY') {
        $_->{nas_name} = $Nas->{list_hash}->{$_->{nas_id}} foreach (@$services_list);
      }
    }
    @services_list = @{$services_list};
  }

  return \@services_list;
}

1;