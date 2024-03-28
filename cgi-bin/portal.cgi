#!/usr/bin/perl

=head1 NAME

  User portal

=cut

BEGIN {
  our $libpath = '../';

  my $sql_type = 'mysql';
  unshift(@INC, $libpath . "AXbills/$sql_type/");
  unshift(@INC, $libpath . "AXbills/");
  unshift(@INC, $libpath . "AXbills/modules/");
  unshift(@INC, $libpath);
  unshift(@INC, $libpath . 'libexec/');
  unshift(@INC, $libpath . '/lib/');
  eval { require Time::HiRes; };
  if (!$@) {
    Time::HiRes->import(qw(gettimeofday));
    $begin_time = gettimeofday();

  }
  else {
    $begin_time = 0;
  }
}

do "../libexec/config.pl";

require AXbills::Templates;
use AXbills::Defs;
use AXbills::Base;
require AXbills::Misc;
# use Portal;

our $html = AXbills::HTML->new(
  {
    IMG_PATH => 'img/',
    NO_PRINT => 1,
    CONF     => \%conf,
    CHARSET  => $conf{default_charset},
  }
);

$html->{language} = $FORM{language} if (defined( $FORM{language} ) && $FORM{language} =~ /[a-z_]/);

do "../language/$html->{language}.pl";
do "../AXbills/modules/Portal/lng_$html->{language}.pl";

print "Content-Type: text/html\n\n";

our $db    = AXbills::SQL->connect($conf{dbtype}, $conf{dbhost}, $conf{dbname}, $conf{dbuser}, $conf{dbpasswd}, { CHARSET => ($conf{dbcharset}) ? $conf{dbcharset} : undef });

$html->{CHARSET} = $CHARSET if ($CHARSET);

load_module('Portal', $html);
portal_s_page();

#my $url = '';
##$Portal->{debug}=1;
#
#my $list = $Portal->portal_menu_list({ MENU_SHOW => 1, COLS_NAME => 1 });
#if ($list->[0]->{id}) {
#  foreach my $line (@$list) {
#
#    # Если поле url пустое, формируем меню
#    if ($line->{url} eq '') {
#      $url = 'portal.cgi?menu_category=' . $line->{id};
#    }
#
#    # Если поле url не пустое формируем внешнюю ссылку
#    else {
#
#      # Если строка содержит http:// выводим как есть
#      if ($line->{url} =~ m|http://*|) {
#        $url = $line->{url};
#      }
#
#      # Если строка не содержит http://  - добавляем
#      else {
#        $url = 'http://' . $line->{url};
#      }
#    }
#
#    # Если нажатое меню не совпадает с активным меню то выводим меню без выделения
#    if ($FORM{menu_category} != $line->{id}) {
#      $OUTPUT{MENU} .= $html->tpl_show(
#        _include('portal_menu', 'Portal'),
#        {
#          HREF      => $url,
#          MENU_NAME => $line->{name},
#        },
#        { OUTPUT2RETURN => 1 }
#      );
#    }
#    else {
#      #  Выделение активного меню
#      $OUTPUT{MENU} .= $html->tpl_show(_include('portal_menu_hovered', 'Portal'), { MENU_NAME => $line->{name}, }, { OUTPUT2RETURN => 1 });
#    }
#  }
#}
#else {
#  # Выводит  сообшение "В системе не созданы разделы"
#  $OUTPUT{MENU} = $lang{NO_MENU};
#}
#
#if ($FORM{menu_category}) {
#
#  # Собираем статьи в категории меню
#  $list = $Portal->portal_articles_list({ ARTICLE_ID => $FORM{menu_category}, COLS_NAME => 1 });
#  if ($list->[0]->{id}) {
#    my $total_articles = 0;
#    foreach my $line (@$list) {
#
#      # Проверка времени публикации статьи
#      if ($line->{utimestamp} <= time()) {
#        $OUTPUT{CONTENT} .= $html->tpl_show(
#          _include('portal_content', 'Portal'),
#          {
#            HREF              => 'portal.cgi?article=' . $line->{id},
#            TITLE             => $line->{title},
#            SHORT_DESCRIPTION => $line->{short_description}
#          },
#          { OUTPUT2RETURN => 1 }
#        );
#        $total_articles++;
#
#      }
#    }
#
#    # Если количество статей - ноль
#    if ($total_articles <= 0) {
#
#      $OUTPUT{CONTENT} .= $html->tpl_show(
#        _include('portal_article', 'Portal'),
#        {
#          TITLE   => '',
#          ARTICLE => $lang{NO_DATA}
#        },
#        { OUTPUT2RETURN => 1 }
#      );
#
#    }
#
#  }
#  else {
#    # Если в данной категории меню нет статтей выводим сообщение - "В этой категории пока нет данных"
#    $OUTPUT{CONTENT} .= $html->tpl_show(
#      _include('portal_article', 'Portal'),
#      {
#        TITLE   => '',
#        ARTICLE => $lang{NO_DATA}
#      },
#      { OUTPUT2RETURN => 1 }
#    );
#  }
#}
#else {
#  # Отображает статьи на главной
#  $list = $Portal->portal_articles_list({ MAIN_PAGE => 1, COLS_NAME => 1 });
#  if ($list->[0]->{id}) {
#
#    # Если дата статьи меньше или такая же как текущая - выводим статью
#    foreach my $line (@$list) {
#      if ($line->{utimestamp} <= time()) {
#        $OUTPUT{CONTENT} .= $html->tpl_show(
#          _include('portal_content', 'Portal'),
#          {
#            HREF              => 'portal.cgi?article=' . $line->{id},
#            TITLE             => $line->{title},
#            SHORT_DESCRIPTION => $line->{short_description}
#          },
#          { OUTPUT2RETURN => 1 }
#        );
#      }
#    }
#  }
#  else {
#    # Выводит сообщение - "В этой категории пока нет данных"
#    $OUTPUT{CONTENT} .= $html->tpl_show(
#      _include('portal_article', 'Portal'),
#      {
#        TITLE   => '',
#        ARTICLE => $lang{NO_DATA}
#      },
#      { OUTPUT2RETURN => 1 }
#    );
#  }
#
#}
#
#if ($FORM{article}) {
#
#  # Отображение статьи польностю
#  $list = $Portal->portal_articles_list({ ID => $FORM{article}, COLS_NAME => 1 });
#  if ($list->[0]->{id}) {
#    my $text_article = convert($list->[0]->{content}, { text2html => 1 });
#    $OUTPUT{CONTENT} = $html->tpl_show(
#      _include('portal_article', 'Portal'),
#      {
#        TITLE   => $list->[0]->{title},
#        ARTICLE => $text_article
#      },
#      { OUTPUT2RETURN => 1 }
#    );
#  }
#
#}
#
#print $html->tpl_show( _include( 'portal_body', 'Portal' ), {
#      %OUTPUT
#    } );

1
