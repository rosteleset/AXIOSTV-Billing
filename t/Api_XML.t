=head1 NAME

  XML API TEST

=cut

use strict;
use warnings;
use lib '.';

BEGIN {
  our $libpath = '../';
  unshift(@INC, $libpath . 'lib');
  unshift(@INC, $libpath . 'AXbills/');
  unshift(@INC, $libpath);

  eval { require Time::HiRes; };
  our $global_begin_time = 0;
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $global_begin_time = Time::HiRes::gettimeofday();
  }
}

use XML::LibXML;
use Try::Tiny qw(try catch);
use AXbills::Fetcher qw(web_request);
use AXbills::Base qw(parse_arguments);
use Data::Dumper;

my $ARGS = parse_arguments(\@ARGV);

# User search
# index.cgi?qindex=7&search_form=1&search=1&type=11&header=1&xml=1&PHONE=12345654321
my @test_list = (
  # {
  #   name   => 'functions_list',
  #   params => {
  #     xml => '1',
  #   },
  #   xsd => q{
  #     <xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  #       <xs:element name="INFO">
  #         <xs:complexType>
  #           <xs:sequence>
  #             <xs:element type="xs:string" name="HEADER_FIXED_CLASS"/>
  #             <xs:element type="xs:string" name="ADMIN_MSGS"/>
  #             <xs:element type="xs:string" name="ADMIN_RESPONSIBLE"/>
  #             <xs:element type="xs:byte" name="AID"/>
  #             <xs:element type="xs:byte" name="EVENTS_ENABLED"/>
  #             <xs:element name="SEL_TYPE_SM">
  #               <xs:complexType>
  #                 <xs:sequence>
  #                   <xs:element name="select">
  #                     <xs:complexType>
  #                       <xs:sequence>
  #                         <xs:element name="option" maxOccurs="unbounded" minOccurs="0">
  #                           <xs:complexType>
  #                             <xs:simpleContent>
  #                               <xs:extension base="xs:string">
  #                                 <xs:attribute type="xs:short" name="value" use="optional"/>
  #                                 <xs:attribute type="xs:byte" name="selected" use="optional"/>
  #                               </xs:extension>
  #                             </xs:simpleContent>
  #                           </xs:complexType>
  #                         </xs:element>
  #                       </xs:sequence>
  #                       <xs:attribute type="xs:string" name="name"/>
  #                     </xs:complexType>
  #                   </xs:element>
  #                 </xs:sequence>
  #               </xs:complexType>
  #             </xs:element>
  #             <xs:element name="SEL_TYPE">
  #               <xs:complexType>
  #                 <xs:sequence>
  #                   <xs:element name="select">
  #                     <xs:complexType>
  #                       <xs:sequence>
  #                         <xs:element name="option" maxOccurs="unbounded" minOccurs="0">
  #                           <xs:complexType>
  #                             <xs:simpleContent>
  #                               <xs:extension base="xs:string">
  #                                 <xs:attribute type="xs:short" name="value" use="optional"/>
  #                                 <xs:attribute type="xs:byte" name="selected" use="optional"/>
  #                               </xs:extension>
  #                             </xs:simpleContent>
  #                           </xs:complexType>
  #                         </xs:element>
  #                       </xs:sequence>
  #                       <xs:attribute type="xs:string" name="name"/>
  #                     </xs:complexType>
  #                   </xs:element>
  #                 </xs:sequence>
  #               </xs:complexType>
  #             </xs:element>
  #             <xs:element type="xs:string" name="FUNCTION_NAME"/>
  #             <xs:element type="xs:string" name="TECHWORK"/>
  #             <xs:element type="xs:string" name="ONLINE_USERS"/>
  #             <xs:element type="xs:string" name="ONLINE_COUNT"/>
  #             <xs:element name="MENU">
  #               <xs:complexType>
  #                 <xs:sequence>
  #                   <xs:element name="MENU" maxOccurs="unbounded" minOccurs="0">
  #                     <xs:complexType>
  #                       <xs:simpleContent>
  #                         <xs:extension base="xs:string">
  #                           <xs:attribute type="xs:string" name="NAME" use="optional"/>
  #                           <xs:attribute type="xs:short" name="ID" use="optional"/>
  #                           <xs:attribute type="xs:string" name="DESCRIBE" use="optional"/>
  #                           <xs:attribute type="xs:string" name="TYPE" use="optional"/>
  #                           <xs:attribute type="xs:short" name="PARENT" use="optional"/>
  #                         </xs:extension>
  #                       </xs:simpleContent>
  #                     </xs:complexType>
  #                   </xs:element>
  #                 </xs:sequence>
  #               </xs:complexType>
  #             </xs:element>
  #             <xs:element type="xs:string" name="BREADCRUMB"/>
  #           </xs:sequence>
  #           <xs:attribute type="xs:string" name="name"/>
  #         </xs:complexType>
  #       </xs:element>
  #     </xs:schema>
  #   }
  # },
  {
    name   => 'form_users_list',
    params => {
      xml            => '1',
      index          => '11',
      EXPORT_CONTENT => 'USERS_LIST',
    },
    xsd => q{
      <xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <xs:element name="TABLE">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="TITLE">
                <xs:complexType>
                  <xs:sequence>
                    <xs:element name="COLUMN_1">
                      <xs:complexType>
                        <xs:simpleContent>
                          <xs:extension base="xs:string">
                            <xs:attribute type="xs:string" name="NAME"/>
                            <xs:attribute type="xs:string" name="ID"/>
                          </xs:extension>
                        </xs:simpleContent>
                      </xs:complexType>
                    </xs:element>
                    <xs:element name="COLUMN_2">
                      <xs:complexType>
                        <xs:simpleContent>
                          <xs:extension base="xs:string">
                            <xs:attribute type="xs:string" name="NAME"/>
                            <xs:attribute type="xs:string" name="ID"/>
                          </xs:extension>
                        </xs:simpleContent>
                      </xs:complexType>
                    </xs:element>
                    <xs:element name="COLUMN_3">
                      <xs:complexType>
                        <xs:simpleContent>
                          <xs:extension base="xs:string">
                            <xs:attribute type="xs:string" name="NAME"/>
                            <xs:attribute type="xs:string" name="ID"/>
                          </xs:extension>
                        </xs:simpleContent>
                      </xs:complexType>
                    </xs:element>
                    <xs:element name="COLUMN_4">
                      <xs:complexType>
                        <xs:simpleContent>
                          <xs:extension base="xs:string">
                            <xs:attribute type="xs:string" name="NAME"/>
                            <xs:attribute type="xs:string" name="ID"/>
                          </xs:extension>
                        </xs:simpleContent>
                      </xs:complexType>
                    </xs:element>
                    <xs:element name="COLUMN_5">
                      <xs:complexType>
                        <xs:simpleContent>
                          <xs:extension base="xs:string">
                            <xs:attribute type="xs:string" name="NAME"/>
                            <xs:attribute type="xs:string" name="ID"/>
                          </xs:extension>
                        </xs:simpleContent>
                      </xs:complexType>
                    </xs:element>
                    <xs:element name="COLUMN_6">
                      <xs:complexType>
                        <xs:simpleContent>
                          <xs:extension base="xs:string">
                            <xs:attribute type="xs:string" name="NAME"/>
                            <xs:attribute type="xs:string" name="ID"/>
                          </xs:extension>
                        </xs:simpleContent>
                      </xs:complexType>
                    </xs:element>
                  </xs:sequence>
                  <xs:attribute type="xs:byte" name="columns"/>
                </xs:complexType>
              </xs:element>
              <xs:element name="DATA">
                <xs:complexType>
                  <xs:sequence>
                    <xs:element name="ROW" maxOccurs="unbounded" minOccurs="0">
                      <xs:complexType>
                        <xs:sequence>
                          <xs:element name="TD" maxOccurs="unbounded" minOccurs="0">
                            <xs:complexType mixed="true">
                              <xs:sequence>
                                <xs:element name="color_mark" minOccurs="0">
                                  <xs:complexType>
                                    <xs:simpleContent>
                                      <xs:extension base="xs:string">
                                        <xs:attribute type="xs:string" name="color" use="optional"/>
                                      </xs:extension>
                                    </xs:simpleContent>
                                  </xs:complexType>
                                </xs:element>
                                <xs:element name="BUTTON" maxOccurs="unbounded" minOccurs="0">
                                  <xs:complexType>
                                    <xs:simpleContent>
                                      <xs:extension base="xs:string">
                                        <xs:attribute type="xs:string" name="VALUE" use="optional"/>
                                      </xs:extension>
                                    </xs:simpleContent>
                                  </xs:complexType>
                                </xs:element>
                              </xs:sequence>
                            </xs:complexType>
                          </xs:element>
                        </xs:sequence>
                      </xs:complexType>
                    </xs:element>
                  </xs:sequence>
                </xs:complexType>
              </xs:element>
            </xs:sequence>
            <xs:attribute type="xs:string" name="CAPTION"/>
            <xs:attribute type="xs:string" name="ID"/>
          </xs:complexType>
        </xs:element>
      </xs:schema>
    }
  },
  # {
  #   name   => 'form_wizard',
  #   params => {
  #     xml         => '1',
  #     get_index   => 'form_wizard',
  #     header      => '1',
  #     add         => '1',
  #     LOGIN       => 'test_user',
  #     CREATE_BILL => '1',
  #     FIO         => 'Test',
  #   },
  #   xsd => q{
  #     <xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  #       <xs:element name="info">
  #         <xs:complexType>
  #           <xs:sequence>
  #             <xs:element name="BUTTON" maxOccurs="unbounded" minOccurs="0">
  #               <xs:complexType>
  #                 <xs:simpleContent>
  #                   <xs:extension base="xs:string">
  #                     <xs:attribute type="xs:string" name="VALUE" use="optional"/>
  #                   </xs:extension>
  #                 </xs:simpleContent>
  #               </xs:complexType>
  #             </xs:element>
  #             <xs:element name="MESSAGE">
  #               <xs:complexType mixed="true">
  #                 <xs:sequence>
  #                   <xs:element name="BUTTON">
  #                     <xs:complexType>
  #                       <xs:simpleContent>
  #                         <xs:extension base="xs:string">
  #                           <xs:attribute type="xs:string" name="VALUE"/>
  #                         </xs:extension>
  #                       </xs:simpleContent>
  #                     </xs:complexType>
  #                   </xs:element>
  #                 </xs:sequence>
  #                 <xs:attribute type="xs:string" name="TYPE"/>
  #                 <xs:attribute type="xs:string" name="CAPTION"/>
  #               </xs:complexType>
  #             </xs:element>
  #           </xs:sequence>
  #         </xs:complexType>
  #       </xs:element>
  #     </xs:schema>
  #   }
  # },
  {
    name   => 'form_users_add',
    params => {
      xml     => '1',
      qindex  => '15',
      header  => '1',
      change  => '1',
      change  => '35',
      UID     => ($ARGS->{UID} || '1'), 
    },
    xsd => q{
      <xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
        <xs:element name="user_info">
          <xs:complexType>
            <xs:sequence>
              <xs:element name="MESSAGE">
                <xs:complexType>
                  <xs:simpleContent>
                    <xs:extension base="xs:string">
                      <xs:attribute type="xs:string" name="TYPE"/>
                      <xs:attribute type="xs:string" name="CAPTION"/>
                    </xs:extension>
                  </xs:simpleContent>
                </xs:complexType>
              </xs:element>
            </xs:sequence>
          </xs:complexType>
        </xs:element>
      </xs:schema>
    }
  },
  # {
  #   name   => 'form_search',
  #   params => {
  #     xml          => '1',
  #     qindex       => '7',
  #     header       => '1',
  #     search_form  => '1',
  #     search       => '35',
  #     type         => '11',
  #     UID          => ($ARGS->{UID} || '2'), 
  #   },
  #   xsd => q{
  #     <xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  #       <xs:element name="user_info">
  #         <xs:complexType>
  #           <xs:sequence>
  #             <xs:element maxOccurs="unbounded" name="div">
  #               <xs:complexType>
  #                 <xs:sequence>
  #                   <xs:choice maxOccurs="unbounded">
  #                     <xs:element name="INFO">
  #                       <xs:complexType>
  #                         <xs:sequence>
  #                           <xs:choice maxOccurs="unbounded">
  #                             <xs:element name="STATUS">
  #                               <xs:complexType mixed="true">
  #                                 <xs:sequence minOccurs="0">
  #                                   <xs:element name="select">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element maxOccurs="unbounded" name="option">
  #                                           <xs:complexType>
  #                                             <xs:simpleContent>
  #                                               <xs:extension base="xs:string">
  #                                                 <xs:attribute name="value" type="xs:unsignedByte" use="required" />
  #                                               </xs:extension>
  #                                             </xs:simpleContent>
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="STATUS_COLOR" />
  #                             <xs:element name="STATUS_COLOR_GR_S" />
  #                             <xs:element name="STATUS_COLOR_GR_F" />
  #                             <xs:element name="STATUS_DAYS" />
  #                             <xs:element name="ID" type="xs:string" />
  #                             <xs:element name="UID" type="xs:unsignedByte" />
  #                             <xs:element name="MENU">
  #                               <xs:complexType>
  #                                 <xs:sequence minOccurs="0">
  #                                   <xs:element maxOccurs="unbounded" name="BUTTON">
  #                                     <xs:complexType>
  #                                       <xs:simpleContent>
  #                                         <xs:extension base="xs:string">
  #                                           <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                         </xs:extension>
  #                                       </xs:simpleContent>
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="DOC_ID" type="xs:unsignedByte" />
  #                             <xs:element name="OP_SID" type="xs:string" />
  #                             <xs:element name="VAT" type="xs:decimal" />
  #                             <xs:element name="CAPTION" type="xs:string" />
  #                             <xs:element name="ONLINE_TABLE" />
  #                             <xs:element name="PAYMENT_MESSAGE" />
  #                             <xs:element name="NEXT_FEES_WARNING" />
  #                             <xs:element name="LAST_LOGIN_MSG">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="MESSAGE">
  #                                     <xs:complexType>
  #                                       <xs:attribute name="TYPE" type="xs:string" use="required" />
  #                                       <xs:attribute name="CAPTION" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="LOGIN_FORM" />
  #                             <xs:element name="TP_ADD" />
  #                             <xs:element name="TP_DISPLAY_NONE" />
  #                             <xs:element name="TP_NUM" type="xs:unsignedByte" />
  #                             <xs:element name="TP_NAME" type="xs:string" />
  #                             <xs:element name="TP_ID" type="xs:unsignedByte" />
  #                             <xs:element name="CHANGE_TP_BUTTON">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="BUTTON">
  #                                     <xs:complexType>
  #                                       <xs:simpleContent>
  #                                         <xs:extension base="xs:string">
  #                                           <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                         </xs:extension>
  #                                       </xs:simpleContent>
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="PERSONAL_TP_MSG" />
  #                             <xs:element name="STATUS_SEL">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="select">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element maxOccurs="unbounded" name="option">
  #                                           <xs:complexType>
  #                                             <xs:simpleContent>
  #                                               <xs:extension base="xs:string">
  #                                                 <xs:attribute name="value" type="xs:unsignedByte" use="required" />
  #                                                 <xs:attribute name="selected" type="xs:unsignedByte" use="optional" />
  #                                               </xs:extension>
  #                                             </xs:simpleContent>
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="SHEDULE">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="BUTTON">
  #                                     <xs:complexType>
  #                                       <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                       <xs:attribute name="TITLE" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="STATUS_INFO" />
  #                             <xs:element name="STATIC_IP_POOL">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="select">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element name="option">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="value" type="xs:string" use="required" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="CHOOSEN_STATIC_IP_POOL" />
  #                             <xs:element name="IP" type="xs:string" />
  #                             <xs:element name="NETMASK_COLOR" />
  #                             <xs:element name="NETMASK" type="xs:string" />
  #                             <xs:element name="CID" type="xs:string" />
  #                             <xs:element name="IPOE_SHOW_BOX" type="xs:string" />
  #                             <xs:element name="NAS_SEL">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="select">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element name="option">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="value" type="xs:string" use="required" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="PORT_SEL">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="select">
  #                                     <xs:complexType>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="VLAN" type="xs:unsignedByte" />
  #                             <xs:element name="VLAN_SEL">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="input">
  #                                     <xs:complexType>
  #                                       <xs:attribute name="type" type="xs:string" use="required" />
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                       <xs:attribute name="value" type="xs:string" use="required" />
  #                                       <xs:attribute name="SIZE" type="xs:unsignedByte" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="IPN_ACTIVATE" />
  #                             <xs:element name="IPN_ACTIVATE_BUTTON" />
  #                             <xs:element name="STATIC_IPV6_POOL">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="select">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element name="option">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="value" type="xs:string" use="required" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="IPV6" />
  #                             <xs:element name="IPV6_MASK_SEL">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="select">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element maxOccurs="unbounded" name="option">
  #                                           <xs:complexType>
  #                                             <xs:simpleContent>
  #                                               <xs:extension base="xs:unsignedByte">
  #                                                 <xs:attribute name="value" type="xs:unsignedByte" use="required" />
  #                                               </xs:extension>
  #                                             </xs:simpleContent>
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="IPV6_PREFIX" />
  #                             <xs:element name="IPV6_PREFIX_MASK_SEL">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="select">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element maxOccurs="unbounded" name="option">
  #                                           <xs:complexType>
  #                                             <xs:simpleContent>
  #                                               <xs:extension base="xs:unsignedByte">
  #                                                 <xs:attribute name="value" type="xs:unsignedByte" use="required" />
  #                                               </xs:extension>
  #                                             </xs:simpleContent>
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="CPE_MAC" />
  #                             <xs:element name="SPEED" type="xs:unsignedByte" />
  #                             <xs:element name="LOGINS" type="xs:unsignedByte" />
  #                             <xs:element name="EXPIRE_COLOR" />
  #                             <xs:element name="SERVICE_ACTIVATE" type="xs:date" />
  #                             <xs:element name="SERVICE_EXPIRE" type="xs:string" />
  #                             <xs:element name="FILTER_ID" />
  #                             <xs:element name="DETAIL_STATS" />
  #                             <xs:element name="PERSONAL_TP" type="xs:unsignedByte" />
  #                             <xs:element name="PERSONAL_TP_DISABLE" type="xs:string" />
  #                             <xs:element name="REGISTRATION_INFO">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="BUTTON">
  #                                     <xs:complexType>
  #                                       <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="REGISTRATION_INFO_PDF">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="BUTTON">
  #                                     <xs:complexType>
  #                                       <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="REGISTRATION_INFO_SMS">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="BUTTON">
  #                                     <xs:complexType>
  #                                       <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="PASSWORD_FORM" />
  #                             <xs:element name="TURBO_MODE_FORM" />
  #                             <xs:element name="BACK_BUTTON" />
  #                             <xs:element name="ACTION" type="xs:string" />
  #                             <xs:element name="LNG_ACTION" type="xs:string" />
  #                             <xs:element name="DEL_BUTTON">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="BUTTON">
  #                                     <xs:complexType>
  #                                       <xs:simpleContent>
  #                                         <xs:extension base="xs:string">
  #                                           <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                         </xs:extension>
  #                                       </xs:simpleContent>
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="EQUIPMENT_FORM">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="INFO">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element name="EQUIPMENT_INFO">
  #                                           <xs:complexType>
  #                                             <xs:sequence>
  #                                               <xs:element name="TABLE">
  #                                                 <xs:complexType>
  #                                                   <xs:sequence>
  #                                                     <xs:element name="DATA" />
  #                                                   </xs:sequence>
  #                                                   <xs:attribute name="ID" type="xs:string" use="required" />
  #                                                 </xs:complexType>
  #                                               </xs:element>
  #                                             </xs:sequence>
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="FORM_INVOICE_ID">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="INFO">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element name="class" />
  #                                         <xs:element name="ID" type="xs:string" />
  #                                         <xs:element name="NAME" type="xs:string" />
  #                                         <xs:element name="BG_COLOR" />
  #                                         <xs:element name="VALUE">
  #                                           <xs:complexType>
  #                                             <xs:sequence>
  #                                               <xs:element name="input">
  #                                                 <xs:complexType>
  #                                                   <xs:attribute name="type" type="xs:string" use="required" />
  #                                                   <xs:attribute name="name" type="xs:string" use="required" />
  #                                                   <xs:attribute name="value" type="xs:string" use="required" />
  #                                                 </xs:complexType>
  #                                               </xs:element>
  #                                             </xs:sequence>
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="DATE_FIELD">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="DATE">
  #                                     <xs:complexType>
  #                                       <xs:attribute name="Y" type="xs:unsignedShort" use="required" />
  #                                       <xs:attribute name="M" type="xs:unsignedByte" use="required" />
  #                                       <xs:attribute name="D" type="xs:unsignedByte" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="CUSTOMER" type="xs:string" />
  #                             <xs:element name="PHONE" type="xs:long" />
  #                             <xs:element name="ORDER_1" />
  #                             <xs:element name="COUNTS_1" />
  #                             <xs:element name="SUM_1" />
  #                             <xs:element name="ACTIVATION" />
  #                             <xs:element name="TP_ID_SELECT">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="select">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element name="option">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="value" type="xs:string" use="required" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="SUBMIT_BTN_NAME" type="xs:string" />
  #                             <xs:element name="MONTHES" />
  #                             <xs:element name="OLD_MAC" />
  #                             <xs:element name="COUNT1" />
  #                             <xs:element name="ARTICLE_ID1" />
  #                             <xs:element name="ARTICLE_TYPES">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="select">
  #                                     <xs:complexType>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="ARTICLE_ID">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="select">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element name="option">
  #                                           <xs:complexType>
  #                                             <xs:simpleContent>
  #                                               <xs:extension base="xs:string">
  #                                                 <xs:attribute name="value" type="xs:string" use="required" />
  #                                                 <xs:attribute name="selected" type="xs:unsignedByte" use="required" />
  #                                               </xs:extension>
  #                                             </xs:simpleContent>
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="COUNT" />
  #                             <xs:element name="DISABLE" type="xs:string" />
  #                             <xs:element name="STORAGE_DOC_CONTRACT" />
  #                             <xs:element name="STORAGE_DOC_RECEIPT" />
  #                             <xs:element name="SERIAL" />
  #                             <xs:element name="INSTALLED_AID_SEL">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="select">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element name="option">
  #                                           <xs:complexType>
  #                                             <xs:simpleContent>
  #                                               <xs:extension base="xs:string">
  #                                                 <xs:attribute name="value" type="xs:string" use="required" />
  #                                               </xs:extension>
  #                                             </xs:simpleContent>
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="GROUNDS" />
  #                             <xs:element name="COMMENTS" />
  #                             <xs:element name="DHCP_ADD_FORM" />
  #                             <xs:element name="TP_IDS" type="xs:unsignedByte" />
  #                             <xs:element name="SUBSCRIBE_FORM">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="INFO">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element name="class" />
  #                                         <xs:element name="ID" type="xs:string" />
  #                                         <xs:element name="NAME" type="xs:string" />
  #                                         <xs:element name="BG_COLOR" />
  #                                         <xs:element name="VALUE">
  #                                           <xs:complexType>
  #                                             <xs:sequence>
  #                                               <xs:element name="select">
  #                                                 <xs:complexType>
  #                                                   <xs:sequence>
  #                                                     <xs:element name="option">
  #                                                       <xs:complexType>
  #                                                         <xs:simpleContent>
  #                                                           <xs:extension base="xs:string">
  #                                                             <xs:attribute name="value" type="xs:unsignedByte" use="required" />
  #                                                           </xs:extension>
  #                                                         </xs:simpleContent>
  #                                                       </xs:complexType>
  #                                                     </xs:element>
  #                                                   </xs:sequence>
  #                                                   <xs:attribute name="name" type="xs:string" use="required" />
  #                                                 </xs:complexType>
  #                                               </xs:element>
  #                                             </xs:sequence>
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="SERVICE_FORM" />
  #                             <xs:element name="EMAIL" />
  #                             <xs:element name="SEND_MESSAGE" />
  #                             <xs:element name="PIN" type="xs:unsignedByte" />
  #                             <xs:element name="VOD" type="xs:unsignedByte" />
  #                             <xs:element name="DVCRYPT_ID" type="xs:unsignedByte" />
  #                             <xs:element name="IPTV_MODEMS" />
  #                             <xs:element name="IPTV_EXPIRE" type="xs:string" />
  #                             <xs:element name="SUBSCRIBE_ID" type="xs:unsignedByte" />
  #                             <xs:element name="EXTERNAL_INFO" />
  #                             <xs:element name="NUMBER" type="xs:unsignedByte" />
  #                             <xs:element name="SIMULTANEOUSLY" type="xs:unsignedByte" />
  #                             <xs:element name="ALLOW_ANSWER" type="xs:string" />
  #                             <xs:element name="ALLOW_CALLS" type="xs:string" />
  #                             <xs:element name="PROVISION">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="INFO">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element name="PARAMS" type="xs:string" />
  #                                         <xs:element name="NAME" type="xs:string" />
  #                                         <xs:element name="CONTENT">
  #                                           <xs:complexType>
  #                                             <xs:sequence>
  #                                               <xs:element name="INFO">
  #                                                 <xs:complexType>
  #                                                   <xs:sequence>
  #                                                     <xs:element name="NAS_SEL">
  #                                                       <xs:complexType>
  #                                                         <xs:sequence>
  #                                                           <xs:element name="select">
  #                                                             <xs:complexType>
  #                                                               <xs:attribute name="name" type="xs:string" use="required" />
  #                                                             </xs:complexType>
  #                                                           </xs:element>
  #                                                         </xs:sequence>
  #                                                       </xs:complexType>
  #                                                     </xs:element>
  #                                                     <xs:element name="PROVISION_PORT" type="xs:unsignedByte" />
  #                                                   </xs:sequence>
  #                                                   <xs:attribute name="name" type="xs:string" use="required" />
  #                                                 </xs:complexType>
  #                                               </xs:element>
  #                                             </xs:sequence>
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="name" type="xs:string" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="VOIP_EXPIRE" type="xs:string" />
  #                           </xs:choice>
  #                         </xs:sequence>
  #                         <xs:attribute name="name" type="xs:string" use="required" />
  #                       </xs:complexType>
  #                     </xs:element>
  #                     <xs:element name="TABLE">
  #                       <xs:complexType>
  #                         <xs:sequence>
  #                           <xs:element minOccurs="0" name="TITLE">
  #                             <xs:complexType>
  #                               <xs:sequence>
  #                                 <xs:element name="COLUMN_1">
  #                                   <xs:complexType>
  #                                     <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                     <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element name="COLUMN_2">
  #                                   <xs:complexType>
  #                                     <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                     <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="COLUMN_3">
  #                                   <xs:complexType>
  #                                     <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                     <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="COLUMN_4">
  #                                   <xs:complexType>
  #                                     <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                     <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="COLUMN_5">
  #                                   <xs:complexType>
  #                                     <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                     <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="COLUMN_6">
  #                                   <xs:complexType>
  #                                     <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                     <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="COLUMN_7">
  #                                   <xs:complexType>
  #                                     <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                     <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="COLUMN_8">
  #                                   <xs:complexType>
  #                                     <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                     <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="COLUMN_9">
  #                                   <xs:complexType>
  #                                     <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                     <xs:attribute name="ID" type="xs:string" use="required" />
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="COLUMN_10">
  #                                   <xs:complexType>
  #                                     <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                     <xs:attribute name="ID" type="xs:string" use="required" />
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="COLUMN_11">
  #                                   <xs:complexType>
  #                                     <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                     <xs:attribute name="ID" type="xs:string" use="required" />
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="COLUMN_12">
  #                                   <xs:complexType>
  #                                     <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                     <xs:attribute name="ID" type="xs:string" use="required" />
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                               </xs:sequence>
  #                               <xs:attribute name="columns" type="xs:unsignedByte" use="required" />
  #                             </xs:complexType>
  #                           </xs:element>
  #                           <xs:element name="DATA">
  #                             <xs:complexType>
  #                               <xs:sequence minOccurs="0">
  #                                 <xs:element maxOccurs="unbounded" name="ROW">
  #                                   <xs:complexType>
  #                                     <xs:sequence>
  #                                       <xs:element maxOccurs="unbounded" name="TD" type="xs:string" />
  #                                     </xs:sequence>
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                               </xs:sequence>
  #                             </xs:complexType>
  #                           </xs:element>
  #                         </xs:sequence>
  #                         <xs:attribute name="CAPTION" type="xs:string" use="optional" />
  #                         <xs:attribute name="ID" type="xs:string" use="required" />
  #                       </xs:complexType>
  #                     </xs:element>
  #                     <xs:element maxOccurs="unbounded" name="div">
  #                       <xs:complexType>
  #                         <xs:sequence>
  #                           <xs:element name="INFO">
  #                             <xs:complexType>
  #                               <xs:sequence>
  #                                 <xs:element name="MAIN_USER_TPL" />
  #                                 <xs:element name="UID" type="xs:unsignedByte" />
  #                                 <xs:element minOccurs="0" name="EDIT_BUTTON">
  #                                   <xs:complexType>
  #                                     <xs:sequence>
  #                                       <xs:element name="BUTTON">
  #                                         <xs:complexType>
  #                                           <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                         </xs:complexType>
  #                                       </xs:element>
  #                                     </xs:sequence>
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="PHOTO" type="xs:string" />
  #                                 <xs:element minOccurs="0" name="FIO" type="xs:string" />
  #                                 <xs:element minOccurs="0" name="ADDRESS_STR" type="xs:string" />
  #                                 <xs:element minOccurs="0" name="MAP_BTN" />
  #                                 <xs:element minOccurs="0" name="PHONE" type="xs:string" />
  #                                 <xs:element minOccurs="0" name="COMMENTS" type="xs:unsignedInt" />
  #                                 <xs:element minOccurs="0" name="ACCEPT_RULES_FORM" />
  #                                 <xs:element minOccurs="0" name="CONTRACT_SUFIX" />
  #                                 <xs:element minOccurs="0" name="CONTRACT_ID" type="xs:unsignedByte" />
  #                                 <xs:element minOccurs="0" name="PRINT_CONTRACT">
  #                                   <xs:complexType>
  #                                     <xs:sequence>
  #                                       <xs:element name="BUTTON">
  #                                         <xs:complexType>
  #                                           <xs:simpleContent>
  #                                             <xs:extension base="xs:string">
  #                                               <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                             </xs:extension>
  #                                           </xs:simpleContent>
  #                                         </xs:complexType>
  #                                       </xs:element>
  #                                     </xs:sequence>
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="CONTRACT_DATE" type="xs:date" />
  #                                 <xs:element minOccurs="0" name="CONTRACT_TYPE" />
  #                                 <xs:element minOccurs="0" name="CONTRACTS_TABLE">
  #                                   <xs:complexType>
  #                                     <xs:sequence>
  #                                       <xs:element name="TABLE">
  #                                         <xs:complexType>
  #                                           <xs:sequence>
  #                                             <xs:element name="TITLE">
  #                                               <xs:complexType>
  #                                                 <xs:sequence>
  #                                                   <xs:element name="COLUMN_0">
  #                                                     <xs:complexType>
  #                                                       <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                                     </xs:complexType>
  #                                                   </xs:element>
  #                                                   <xs:element name="COLUMN_1">
  #                                                     <xs:complexType>
  #                                                       <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                                     </xs:complexType>
  #                                                   </xs:element>
  #                                                   <xs:element name="COLUMN_2">
  #                                                     <xs:complexType>
  #                                                       <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                                     </xs:complexType>
  #                                                   </xs:element>
  #                                                   <xs:element name="COLUMN_3">
  #                                                     <xs:complexType>
  #                                                       <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                                     </xs:complexType>
  #                                                   </xs:element>
  #                                                 </xs:sequence>
  #                                                 <xs:attribute name="columns" type="xs:unsignedByte" use="required" />
  #                                               </xs:complexType>
  #                                             </xs:element>
  #                                             <xs:element name="DATA" />
  #                                           </xs:sequence>
  #                                           <xs:attribute name="CAPTION" type="xs:string" use="required" />
  #                                           <xs:attribute name="ID" type="xs:string" use="required" />
  #                                         </xs:complexType>
  #                                       </xs:element>
  #                                     </xs:sequence>
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="INFO_FIELDS" />
  #                                 <xs:element minOccurs="0" name="DISABLE_MARK" />
  #                                 <xs:element minOccurs="0" name="DEPOSIT_MARK" type="xs:string" />
  #                                 <xs:element minOccurs="0" name="SHOW_DEPOSIT" type="xs:decimal" />
  #                                 <xs:element minOccurs="0" name="PAYMENTS_BUTTON">
  #                                   <xs:complexType>
  #                                     <xs:sequence>
  #                                       <xs:element name="BUTTON">
  #                                         <xs:complexType>
  #                                           <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                         </xs:complexType>
  #                                       </xs:element>
  #                                     </xs:sequence>
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="FEES_BUTTON">
  #                                   <xs:complexType>
  #                                     <xs:sequence>
  #                                       <xs:element name="BUTTON">
  #                                         <xs:complexType>
  #                                           <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                         </xs:complexType>
  #                                       </xs:element>
  #                                     </xs:sequence>
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="PRINT_BUTTON">
  #                                   <xs:complexType>
  #                                     <xs:sequence>
  #                                       <xs:element name="BUTTON">
  #                                         <xs:complexType>
  #                                           <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                         </xs:complexType>
  #                                       </xs:element>
  #                                     </xs:sequence>
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="CREDIT_READONLY" />
  #                                 <xs:element minOccurs="0" name="CREDIT" type="xs:unsignedByte" />
  #                                 <xs:element minOccurs="0" name="CREDIT_DATE_READONLY" />
  #                                 <xs:element minOccurs="0" name="CREDIT_DATE" type="xs:string" />
  #                                 <xs:element minOccurs="0" name="ACTIVATE" type="xs:date" />
  #                                 <xs:element minOccurs="0" name="ACTIVATE_READONLY" />
  #                                 <xs:element minOccurs="0" name="EXPIRE_COLOR" />
  #                                 <xs:element minOccurs="0" name="EXPIRE" type="xs:string" />
  #                                 <xs:element minOccurs="0" name="EXPIRE_READONLY" />
  #                                 <xs:element minOccurs="0" name="REDUCTION_READONLY" />
  #                                 <xs:element minOccurs="0" name="REDUCTION" type="xs:unsignedByte" />
  #                                 <xs:element minOccurs="0" name="REDUCTION_DATE_READONLY" />
  #                                 <xs:element minOccurs="0" name="REDUCTION_DATE" type="xs:string" />
  #                                 <xs:element minOccurs="0" name="COMPANY_NAME" />
  #                                 <xs:element minOccurs="0" name="COMPANY_ID" type="xs:unsignedByte" />
  #                                 <xs:element minOccurs="0" name="GID" type="xs:unsignedByte" />
  #                                 <xs:element minOccurs="0" name="G_NAME" type="xs:string" />
  #                                 <xs:element minOccurs="0" name="GRP_ERR" />
  #                                 <xs:element minOccurs="0" name="REGISTRATION" type="xs:date" />
  #                                 <xs:element minOccurs="0" name="BILL_ID" type="xs:unsignedByte" />
  #                                 <xs:element minOccurs="0" name="BILL_CORRECTION">
  #                                   <xs:complexType>
  #                                     <xs:sequence>
  #                                       <xs:element name="BUTTON">
  #                                         <xs:complexType>
  #                                           <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                         </xs:complexType>
  #                                       </xs:element>
  #                                     </xs:sequence>
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="PASSWORD">
  #                                   <xs:complexType>
  #                                     <xs:sequence>
  #                                       <xs:element maxOccurs="unbounded" name="BUTTON">
  #                                         <xs:complexType>
  #                                           <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                           <xs:attribute name="TITLE" type="xs:string" use="optional" />
  #                                         </xs:complexType>
  #                                       </xs:element>
  #                                     </xs:sequence>
  #                                   </xs:complexType>
  #                                 </xs:element>
  #                                 <xs:element minOccurs="0" name="DISABLE" />
  #                                 <xs:element minOccurs="0" name="DISABLE_COLOR" />
  #                                 <xs:element minOccurs="0" name="DISABLE_COMMENTS" />
  #                                 <xs:element minOccurs="0" name="ACTION_COMMENTS" />
  #                                 <xs:element minOccurs="0" name="DEL_FORM" />
  #                                 <xs:element minOccurs="0" name="ACTION" type="xs:string" />
  #                                 <xs:element minOccurs="0" name="LNG_ACTION" type="xs:string" />
  #                               </xs:sequence>
  #                               <xs:attribute name="name" type="xs:string" use="required" />
  #                             </xs:complexType>
  #                           </xs:element>
  #                         </xs:sequence>
  #                         <xs:attribute name="class" type="xs:string" use="required" />
  #                       </xs:complexType>
  #                     </xs:element>
  #                     <xs:element name="FORM">
  #                       <xs:complexType>
  #                         <xs:sequence>
  #                           <xs:choice maxOccurs="unbounded">
  #                             <xs:element maxOccurs="unbounded" name="input">
  #                               <xs:complexType>
  #                                 <xs:attribute name="name" type="xs:string" use="required" />
  #                                 <xs:attribute name="value" type="xs:string" use="required" />
  #                                 <xs:attribute name="type" type="xs:string" use="optional" />
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="TABLE">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element name="TITLE">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element name="COLUMN_1">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                             <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                         <xs:element name="COLUMN_2">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                             <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                         <xs:element name="COLUMN_3">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                             <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                         <xs:element name="COLUMN_4">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                             <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                         <xs:element minOccurs="0" name="COLUMN_5">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                             <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                         <xs:element minOccurs="0" name="COLUMN_6">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                             <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                         <xs:element minOccurs="0" name="COLUMN_7">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                             <xs:attribute name="ID" type="xs:string" use="optional" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                         <xs:element minOccurs="0" name="COLUMN_8">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                         <xs:element minOccurs="0" name="COLUMN_9">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                         <xs:element minOccurs="0" name="COLUMN_10">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                         <xs:element minOccurs="0" name="COLUMN_11">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                         <xs:element minOccurs="0" name="COLUMN_12">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                         <xs:element minOccurs="0" name="COLUMN_13">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                         <xs:element minOccurs="0" name="COLUMN_14">
  #                                           <xs:complexType>
  #                                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                       <xs:attribute name="columns" type="xs:unsignedByte" use="required" />
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                   <xs:element name="DATA">
  #                                     <xs:complexType>
  #                                       <xs:sequence>
  #                                         <xs:element maxOccurs="unbounded" name="ROW">
  #                                           <xs:complexType>
  #                                             <xs:sequence>
  #                                               <xs:element maxOccurs="unbounded" name="TD" type="xs:string" />
  #                                             </xs:sequence>
  #                                           </xs:complexType>
  #                                         </xs:element>
  #                                       </xs:sequence>
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                                 <xs:attribute name="CAPTION" type="xs:string" use="required" />
  #                                 <xs:attribute name="ID" type="xs:string" use="required" />
  #                               </xs:complexType>
  #                             </xs:element>
  #                             <xs:element name="select">
  #                               <xs:complexType>
  #                                 <xs:sequence>
  #                                   <xs:element maxOccurs="unbounded" name="option">
  #                                     <xs:complexType>
  #                                       <xs:simpleContent>
  #                                         <xs:extension base="xs:string">
  #                                           <xs:attribute name="value" type="xs:string" use="required" />
  #                                           <xs:attribute name="selected" type="xs:unsignedByte" use="optional" />
  #                                         </xs:extension>
  #                                       </xs:simpleContent>
  #                                     </xs:complexType>
  #                                   </xs:element>
  #                                 </xs:sequence>
  #                                 <xs:attribute name="name" type="xs:string" use="required" />
  #                               </xs:complexType>
  #                             </xs:element>
  #                           </xs:choice>
  #                         </xs:sequence>
  #                         <xs:attribute name="action" type="xs:string" use="required" />
  #                       </xs:complexType>
  #                     </xs:element>
  #                     <xs:element name="table_header">
  #                       <xs:complexType>
  #                         <xs:sequence>
  #                           <xs:element maxOccurs="unbounded" name="BUTTON">
  #                             <xs:complexType>
  #                               <xs:simpleContent>
  #                                 <xs:extension base="xs:string">
  #                                   <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                                 </xs:extension>
  #                               </xs:simpleContent>
  #                             </xs:complexType>
  #                           </xs:element>
  #                         </xs:sequence>
  #                       </xs:complexType>
  #                     </xs:element>
  #                   </xs:choice>
  #                 </xs:sequence>
  #                 <xs:attribute name="class" type="xs:string" use="required" />
  #               </xs:complexType>
  #             </xs:element>
  #             <xs:element name="INFO">
  #               <xs:complexType>
  #                 <xs:sequence>
  #                   <xs:element name="SEL_TYPE" />
  #                   <xs:element name="HIDDEN_FIELDS" />
  #                   <xs:element name="LOGIN" />
  #                   <xs:element name="PAGE_ROWS" />
  #                   <xs:element name="HIDE_DATE" type="xs:string" />
  #                   <xs:element name="FROM_DATE" />
  #                   <xs:element name="TO_DATE" />
  #                   <xs:element name="GROUPS_SEL">
  #                     <xs:complexType>
  #                       <xs:sequence>
  #                         <xs:element name="select">
  #                           <xs:complexType>
  #                             <xs:sequence>
  #                               <xs:element name="option">
  #                                 <xs:complexType>
  #                                   <xs:simpleContent>
  #                                     <xs:extension base="xs:string">
  #                                       <xs:attribute name="value" type="xs:string" use="required" />
  #                                     </xs:extension>
  #                                   </xs:simpleContent>
  #                                 </xs:complexType>
  #                               </xs:element>
  #                             </xs:sequence>
  #                             <xs:attribute name="name" type="xs:string" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                       </xs:sequence>
  #                     </xs:complexType>
  #                   </xs:element>
  #                   <xs:element name="TAGS_SEL">
  #                     <xs:complexType>
  #                       <xs:sequence>
  #                         <xs:element name="select">
  #                           <xs:complexType>
  #                             <xs:attribute name="name" type="xs:string" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                       </xs:sequence>
  #                     </xs:complexType>
  #                   </xs:element>
  #                   <xs:element name="ADDRESS_FORM">
  #                     <xs:complexType>
  #                       <xs:sequence>
  #                         <xs:element name="INFO">
  #                           <xs:complexType>
  #                             <xs:sequence>
  #                               <xs:element name="PARAMS" />
  #                               <xs:element name="NAME" type="xs:string" />
  #                               <xs:element name="CONTENT">
  #                                 <xs:complexType>
  #                                   <xs:sequence>
  #                                     <xs:element name="INFO">
  #                                       <xs:complexType>
  #                                         <xs:sequence>
  #                                           <xs:element name="DISTRICT_ID" type="xs:unsignedByte" />
  #                                           <xs:element name="STREET_ID" type="xs:unsignedByte" />
  #                                           <xs:element name="LOCATION_ID" type="xs:unsignedByte" />
  #                                           <xs:element name="ADDRESS_DISTRICT" type="xs:string" />
  #                                           <xs:element name="ADDRESS_STREET" type="xs:string" />
  #                                           <xs:element name="ADDRESS_STREET2" type="xs:string" />
  #                                           <xs:element name="ADDRESS_BUILD" type="xs:unsignedByte" />
  #                                           <xs:element name="ADDRESS_FLAT" type="xs:unsignedByte" />
  #                                           <xs:element name="FLAT_CHECK_FREE" />
  #                                           <xs:element name="FLAT_CHECK_OCCUPIED" />
  #                                         </xs:sequence>
  #                                         <xs:attribute name="name" type="xs:string" use="required" />
  #                                       </xs:complexType>
  #                                     </xs:element>
  #                                   </xs:sequence>
  #                                 </xs:complexType>
  #                               </xs:element>
  #                             </xs:sequence>
  #                             <xs:attribute name="name" type="xs:string" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                       </xs:sequence>
  #                     </xs:complexType>
  #                   </xs:element>
  #                   <xs:element name="SEARCH_FORM">
  #                     <xs:complexType>
  #                       <xs:sequence>
  #                         <xs:element name="INFO">
  #                           <xs:complexType>
  #                             <xs:sequence>
  #                               <xs:element name="FIO" />
  #                               <xs:element name="CONTRACT_ID" />
  #                               <xs:element name="CONTRACT_TYPE_FORM" />
  #                               <xs:element name="CONTRACT_DATE" />
  #                               <xs:element name="PHONE" />
  #                               <xs:element name="COMMENTS" />
  #                               <xs:element name="GROUPS_SEL">
  #                                 <xs:complexType>
  #                                   <xs:sequence>
  #                                     <xs:element name="select">
  #                                       <xs:complexType>
  #                                         <xs:sequence>
  #                                           <xs:element name="option">
  #                                             <xs:complexType>
  #                                               <xs:simpleContent>
  #                                                 <xs:extension base="xs:string">
  #                                                   <xs:attribute name="value" type="xs:string" use="required" />
  #                                                 </xs:extension>
  #                                               </xs:simpleContent>
  #                                             </xs:complexType>
  #                                           </xs:element>
  #                                         </xs:sequence>
  #                                         <xs:attribute name="name" type="xs:string" use="required" />
  #                                       </xs:complexType>
  #                                     </xs:element>
  #                                   </xs:sequence>
  #                                 </xs:complexType>
  #                               </xs:element>
  #                               <xs:element name="DEPOSIT" />
  #                               <xs:element name="BILL_ID" />
  #                               <xs:element name="DOMAIN_FORM" />
  #                               <xs:element name="UID" type="xs:unsignedByte" />
  #                               <xs:element name="EMAIL" />
  #                               <xs:element name="REGISTRATION" />
  #                               <xs:element name="ACTIVATE" />
  #                               <xs:element name="EXPIRE" />
  #                               <xs:element name="REDUCTION" />
  #                               <xs:element name="REDUCTION_DATE" />
  #                               <xs:element name="CREDIT" />
  #                               <xs:element name="CREDIT_DATE" />
  #                               <xs:element name="PAYMENTS" />
  #                               <xs:element name="PAYMENT_DAYS" />
  #                               <xs:element name="FEES" />
  #                               <xs:element name="FEES_DAYS" />
  #                               <xs:element name="PASPORT_NUM" />
  #                               <xs:element name="PASPORT_DATE" />
  #                               <xs:element name="PASPORT_GRANT" />
  #                               <xs:element name="INFO_FIELDS" />
  #                             </xs:sequence>
  #                             <xs:attribute name="name" type="xs:string" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                         <xs:element name="input">
  #                           <xs:complexType>
  #                             <xs:attribute name="type" type="xs:string" use="required" />
  #                             <xs:attribute name="name" type="xs:string" use="required" />
  #                             <xs:attribute name="value" type="xs:unsignedByte" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                       </xs:sequence>
  #                     </xs:complexType>
  #                   </xs:element>
  #                 </xs:sequence>
  #                 <xs:attribute name="name" type="xs:string" use="required" />
  #               </xs:complexType>
  #             </xs:element>
  #           </xs:sequence>
  #         </xs:complexType>
  #       </xs:element>
  #     </xs:schema>
  #   }
  # },
  # {
  #   name   => 'dv_user',
  #   params => {
  #     xml            => '1',
  #     get_index      => 'dv_user',
  #     header         => '1',
  #     UID            => ($ARGS->{UID} || '1'), 
  #   },
  #   xsd => q{
    
  #   }
  # },
  # {
  #   name   => 'docs_invoices_list',
  #   params => {
  #     xml            => '1',
  #     full           => '1',
  #     sort           => '1',
  #     EXPORT_CONTENT => 'DOCS_INVOICES_LIST',
  #     get_index      => 'docs_invoices_list',
  #     PAGE_ROWS      => '1000000',
  #     header         => '1',
  #   },
  #   xsd => q{
  #     <xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  #       <xs:element name="FORM">
  #         <xs:complexType>
  #           <xs:sequence>
  #             <xs:choice maxOccurs="unbounded">
  #               <xs:element maxOccurs="unbounded" name="input">
  #                 <xs:complexType>
  #                   <xs:attribute name="name" type="xs:string" use="required" />
  #                   <xs:attribute name="value" type="xs:string" use="required" />
  #                   <xs:attribute name="type" type="xs:string" use="optional" />
  #                 </xs:complexType>
  #               </xs:element>
  #               <xs:element name="TABLE">
  #                 <xs:complexType>
  #                   <xs:sequence>
  #                     <xs:element name="TITLE">
  #                       <xs:complexType>
  #                         <xs:sequence>
  #                           <xs:element name="COLUMN_1">
  #                             <xs:complexType>
  #                               <xs:attribute name="NAME" type="xs:string" use="required" />
  #                               <xs:attribute name="ID" type="xs:string" use="required" />
  #                             </xs:complexType>
  #                           </xs:element>
  #                           <xs:element name="COLUMN_2">
  #                             <xs:complexType>
  #                               <xs:attribute name="NAME" type="xs:string" use="required" />
  #                               <xs:attribute name="ID" type="xs:string" use="required" />
  #                             </xs:complexType>
  #                           </xs:element>
  #                           <xs:element name="COLUMN_3">
  #                             <xs:complexType>
  #                               <xs:attribute name="NAME" type="xs:string" use="required" />
  #                               <xs:attribute name="ID" type="xs:string" use="required" />
  #                             </xs:complexType>
  #                           </xs:element>
  #                           <xs:element name="COLUMN_4">
  #                             <xs:complexType>
  #                               <xs:attribute name="NAME" type="xs:string" use="required" />
  #                               <xs:attribute name="ID" type="xs:string" use="required" />
  #                             </xs:complexType>
  #                           </xs:element>
  #                           <xs:element name="COLUMN_5">
  #                             <xs:complexType>
  #                               <xs:attribute name="NAME" type="xs:string" use="required" />
  #                               <xs:attribute name="ID" type="xs:string" use="required" />
  #                             </xs:complexType>
  #                           </xs:element>
  #                           <xs:element name="COLUMN_6">
  #                             <xs:complexType>
  #                               <xs:attribute name="NAME" type="xs:string" use="required" />
  #                               <xs:attribute name="ID" type="xs:string" use="required" />
  #                             </xs:complexType>
  #                           </xs:element>
  #                           <xs:element name="COLUMN_7">
  #                             <xs:complexType>
  #                               <xs:attribute name="NAME" type="xs:string" use="required" />
  #                               <xs:attribute name="ID" type="xs:string" use="required" />
  #                             </xs:complexType>
  #                           </xs:element>
  #                           <xs:element name="COLUMN_8">
  #                             <xs:complexType>
  #                               <xs:attribute name="NAME" type="xs:string" use="required" />
  #                               <xs:attribute name="ID" type="xs:string" use="required" />
  #                             </xs:complexType>
  #                           </xs:element>
  #                         </xs:sequence>
  #                         <xs:attribute name="columns" type="xs:unsignedByte" use="required" />
  #                       </xs:complexType>
  #                     </xs:element>
  #                     <xs:element name="DATA">
  #                       <xs:complexType>
  #                         <xs:sequence>
  #                           <xs:element maxOccurs="unbounded" name="ROW">
  #                             <xs:complexType>
  #                               <xs:sequence>
  #                                 <xs:element maxOccurs="unbounded" name="TD" type="xs:string" />
  #                               </xs:sequence>
  #                             </xs:complexType>
  #                           </xs:element>
  #                         </xs:sequence>
  #                       </xs:complexType>
  #                     </xs:element>
  #                   </xs:sequence>
  #                   <xs:attribute name="CAPTION" type="xs:string" use="required" />
  #                   <xs:attribute name="ID" type="xs:string" use="required" />
  #                 </xs:complexType>
  #               </xs:element>
  #               <xs:element name="select">
  #                 <xs:complexType>
  #                   <xs:sequence>
  #                     <xs:element maxOccurs="unbounded" name="option">
  #                       <xs:complexType>
  #                         <xs:simpleContent>
  #                           <xs:extension base="xs:string">
  #                             <xs:attribute name="value" type="xs:string" use="required" />
  #                             <xs:attribute name="selected" type="xs:unsignedByte" use="optional" />
  #                           </xs:extension>
  #                         </xs:simpleContent>
  #                       </xs:complexType>
  #                     </xs:element>
  #                   </xs:sequence>
  #                   <xs:attribute name="name" type="xs:string" use="required" />
  #                 </xs:complexType>
  #               </xs:element>
  #             </xs:choice>
  #           </xs:sequence>
  #           <xs:attribute name="action" type="xs:string" use="required" />
  #         </xs:complexType>
  #       </xs:element>
  #     </xs:schema>
  #   }
  # },
  # {
  #   name   => 'form_nas',
  #   params => {
  #     add       => '1',
  #     NAS_NAME  => 'test_geo2',
  #     xml       => '1',
  #     get_index => 'form_nas',
  #     header    => '1',
  #     IP        => '22.11.11.11',
  #   },
  #   xsd => q{
  #     <xs:schema attributeFormDefault="unqualified" elementFormDefault="qualified" xmlns:xs="http://www.w3.org/2001/XMLSchema">
  #       <xs:element name="info">
  #         <xs:complexType>
  #           <xs:sequence>
  #             <xs:element name="MESSAGE">
  #               <xs:complexType>
  #                 <xs:simpleContent>
  #                   <xs:extension base="xs:string">
  #                     <xs:attribute name="TYPE" type="xs:string" use="required" />
  #                     <xs:attribute name="CAPTION" type="xs:string" use="required" />
  #                   </xs:extension>
  #                 </xs:simpleContent>
  #               </xs:complexType>
  #             </xs:element>
  #             <xs:element name="FORM">
  #               <xs:complexType mixed="true">
  #                 <xs:sequence>
  #                   <xs:choice maxOccurs="unbounded">
  #                     <xs:element name="input">
  #                       <xs:complexType>
  #                         <xs:attribute name="name" type="xs:string" use="required" />
  #                         <xs:attribute name="value" type="xs:string" use="required" />
  #                         <xs:attribute name="type" type="xs:string" use="optional" />
  #                       </xs:complexType>
  #                     </xs:element>
  #                     <xs:element name="select">
  #                       <xs:complexType>
  #                         <xs:sequence>
  #                           <xs:element name="option">
  #                             <xs:complexType>
  #                               <xs:attribute name="value" type="xs:string" use="required" />
  #                               <xs:attribute name="selected" type="xs:unsignedByte" use="required" />
  #                             </xs:complexType>
  #                           </xs:element>
  #                         </xs:sequence>
  #                         <xs:attribute name="name" type="xs:string" use="required" />
  #                       </xs:complexType>
  #                     </xs:element>
  #                   </xs:choice>
  #                 </xs:sequence>
  #                 <xs:attribute name="action" type="xs:string" use="required" />
  #               </xs:complexType>
  #             </xs:element>
  #             <xs:element name="table_header">
  #               <xs:complexType>
  #                 <xs:sequence>
  #                   <xs:element maxOccurs="unbounded" name="BUTTON">
  #                     <xs:complexType>
  #                       <xs:simpleContent>
  #                         <xs:extension base="xs:string">
  #                           <xs:attribute name="VALUE" type="xs:string" use="required" />
  #                         </xs:extension>
  #                       </xs:simpleContent>
  #                     </xs:complexType>
  #                   </xs:element>
  #                 </xs:sequence>
  #               </xs:complexType>
  #             </xs:element>
  #             <xs:element maxOccurs="unbounded" name="TABLE">
  #               <xs:complexType>
  #                 <xs:sequence>
  #                   <xs:element minOccurs="0" name="TITLE">
  #                     <xs:complexType>
  #                       <xs:sequence>
  #                         <xs:element name="COLUMN_1">
  #                           <xs:complexType>
  #                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                             <xs:attribute name="ID" type="xs:string" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                         <xs:element name="COLUMN_2">
  #                           <xs:complexType>
  #                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                             <xs:attribute name="ID" type="xs:string" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                         <xs:element name="COLUMN_3">
  #                           <xs:complexType>
  #                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                             <xs:attribute name="ID" type="xs:string" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                         <xs:element name="COLUMN_4">
  #                           <xs:complexType>
  #                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                             <xs:attribute name="ID" type="xs:string" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                         <xs:element name="COLUMN_5">
  #                           <xs:complexType>
  #                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                             <xs:attribute name="ID" type="xs:string" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                         <xs:element name="COLUMN_6">
  #                           <xs:complexType>
  #                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                             <xs:attribute name="ID" type="xs:string" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                         <xs:element name="COLUMN_7">
  #                           <xs:complexType>
  #                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                             <xs:attribute name="ID" type="xs:string" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                         <xs:element name="COLUMN_8">
  #                           <xs:complexType>
  #                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                             <xs:attribute name="ID" type="xs:string" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                         <xs:element name="COLUMN_9">
  #                           <xs:complexType>
  #                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                             <xs:attribute name="ID" type="xs:string" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                         <xs:element name="COLUMN_10">
  #                           <xs:complexType>
  #                             <xs:attribute name="NAME" type="xs:string" use="required" />
  #                             <xs:attribute name="ID" type="xs:string" use="required" />
  #                           </xs:complexType>
  #                         </xs:element>
  #                       </xs:sequence>
  #                       <xs:attribute name="columns" type="xs:unsignedByte" use="required" />
  #                     </xs:complexType>
  #                   </xs:element>
  #                   <xs:element name="DATA">
  #                     <xs:complexType>
  #                       <xs:sequence>
  #                         <xs:element maxOccurs="unbounded" name="ROW">
  #                           <xs:complexType>
  #                             <xs:sequence>
  #                               <xs:element maxOccurs="unbounded" name="TD" type="xs:string" />
  #                             </xs:sequence>
  #                           </xs:complexType>
  #                         </xs:element>
  #                       </xs:sequence>
  #                     </xs:complexType>
  #                   </xs:element>
  #                 </xs:sequence>
  #                 <xs:attribute name="CAPTION" type="xs:string" use="optional" />
  #                 <xs:attribute name="ID" type="xs:string" use="required" />
  #               </xs:complexType>
  #             </xs:element>
  #           </xs:sequence>
  #         </xs:complexType>
  #       </xs:element>
  #     </xs:schema>                      
  #   } 
  # },
);
  
xml_test(\@test_list, { TEST_NAME => 'XML TEST API' });

sub xml_test{
  my ($test_list) = @_;

  my $count = 1;

  foreach my $function (@$test_list){

    next if($ARGS->{REQUEST} && $ARGS->{REQUEST} ne $function->{name});

    my %request_params  = ();

    if($ARGS->{USER})    {$request_params{user}    = $ARGS->{USER}};
    if($ARGS->{PASSWD})  {$request_params{passwd}  = $ARGS->{PASSWD}};
    if($ARGS->{API_KEY}) {$request_params{API_KEY} = $ARGS->{API_KEY}};

    foreach my $param (keys %{$function->{params}}){
      $request_params{$param} = $function->{params}->{$param};
    }

    my $xml = web_request(($ARGS->{URL} || 'https://127.0.0.1:9443') . '/admin/index.cgi', 
      {
        CURL_OPTIONS   => '-k',
        REQUEST_PARAMS => \%request_params,
        DEBUG          => $ARGS->{DEBUG},
      } 
    );
# print $xml;
# next;
    my $xml_doc = XML::LibXML->load_xml(string  => $xml);
    my $xsd_doc = XML::LibXML::Schema->new(string => $function->{xsd});

    my $is_xml_valid = try {
        not $xsd_doc->validate($xml_doc);
    }
    catch {
        print $count . '.' .$function->{name}. ' WARNING ==> ' . $_;
        # return 0;
    };

    print $count . '.' . $function->{name} . ': ' . ($is_xml_valid ? 'OK' : 'Not OK') . "\n";
    $count++;

    last if($ARGS->{REQUEST} && $ARGS->{REQUEST} eq $function->{name});
  }
   
}

