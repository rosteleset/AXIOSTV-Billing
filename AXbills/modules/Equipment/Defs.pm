=head1 NAME

  Equipment Defs

=cut

our @skip_ports_types = (135, 142, 136, 1, 24, 250, 300, 53,
  161 # ieee8023adLag
);
if (ref $conf{EQUIPMENT_SKIP_PORTS_TYPES} eq 'ARRAY') {
  @skip_ports_types = @{$conf{EQUIPMENT_SKIP_PORTS_TYPES}};
}

our @port_types = ('', 'RJ45', 'GBIC', 'Gigabit', 'SFP', 'QSFP', 'EPON', 'GPON', 'SFP-RJ45', 'no port');


1;