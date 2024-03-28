<script src='/styles/default/js/chat/%SCRIPT%'></script>
<!--Chat notification-->
<li class='dropdown messages-menu'>
  <a href='#' id="chat_open" fn_index='%FN_INDEX%' type='button' title='_{CHAT}_ _{MESSAGES}_'
     class="dropdown-toggle"
     data-toggle="dropdown">
    <i class='fa fa-comment'></i>
    <span id='chat2' class='icon-label label label-danger hidden'>0</span>
    <span id='id_for_chat' %SIDE_ID% class='hidden'></span>
  </a>
  <ul class="dropdown-menu" role="menu">
    <li class="header">_{YOU_HAVE_NEW_REPLY}_ </li>
    <li>
      <ul id="chats_list" class="menu"></ul>
    </li>
    <li class="footer"><a href="index.cgi?get_index=msgs_admin&full=1">_{ALL}__{MESSAGES}_</a></li>
  </ul>
</li>
<!--End Chat notification-->